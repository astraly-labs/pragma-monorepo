use std::str::FromStr;

use anyhow::{anyhow, bail, Context, Result};
use apibara_core::{
    node::v1alpha2::DataFinality,
    starknet::v1alpha2::{Block, Event, FieldElement, Filter, HeaderFilter},
};
use apibara_sdk::{configuration, ClientBuilder, Configuration, DataMessage, Uri};
use futures_util::TryStreamExt;
use starknet::core::utils::get_selector_from_name;
use tokio::task::JoinSet;

use pragma_utils::{conversions::apibara::felt_as_apibara_field, services::Service};

use crate::{
    storage::DispatchUpdateInfos,
    types::hyperlane::{DispatchEvent, FromStarknetEventData, HasFeedId, ValidatorAnnouncementEvent},
    AppState, HYPERLANE_CORE_CONTRACT_ADDRESS,
};

// TODO: Everything below here should be configurable, either via CLI or config file.
// See: https://github.com/astraly-labs/pragma-monorepo/issues/17
const INDEXING_STREAM_CHUNK_SIZE: usize = 256;
lazy_static::lazy_static! {
    pub static ref F_HYPERLANE_CORE_CONTRACT_ADDRESS: FieldElement = felt_as_apibara_field(&HYPERLANE_CORE_CONTRACT_ADDRESS);
    pub static ref DISPATCH_EVENT_SELECTOR: FieldElement = felt_as_apibara_field(&get_selector_from_name("Dispatch").unwrap());
    pub static ref VALIDATOR_ANNOUNCEMENT_SELECTOR: FieldElement = felt_as_apibara_field(&get_selector_from_name("ValidatorAnnouncement").unwrap());
}

#[derive(Clone)]
pub struct IndexerService {
    state: AppState,
    uri: Uri,
    apibara_api_key: String,
    stream_config: Configuration<Filter>,
}

#[async_trait::async_trait]
impl Service for IndexerService {
    async fn start(&mut self, join_set: &mut JoinSet<anyhow::Result<()>>) -> anyhow::Result<()> {
        let service = self.clone();
        join_set.spawn(async move {
            tracing::info!("🧩 Indexer service started");
            service.run_forever().await?;
            Ok(())
        });
        Ok(())
    }
}

impl IndexerService {
    pub fn new(state: AppState, apibara_uri: &str, apibara_api_key: String) -> Result<Self> {
        let uri = Uri::from_str(apibara_uri)?;

        let stream_config = Configuration::<Filter>::default()
            .with_finality(DataFinality::DataStatusPending)
            .with_filter(|mut filter| {
                filter
                    .with_header(HeaderFilter::weak())
                    .add_event(|event| {
                        event
                            .with_from_address(F_HYPERLANE_CORE_CONTRACT_ADDRESS.clone())
                            .with_keys(vec![DISPATCH_EVENT_SELECTOR.clone()])
                    })
                    .add_event(|event| {
                        event
                            .with_from_address(F_HYPERLANE_CORE_CONTRACT_ADDRESS.clone())
                            .with_keys(vec![VALIDATOR_ANNOUNCEMENT_SELECTOR.clone()])
                    })
                    .build()
            });

        let indexer_service = Self { state, uri, apibara_api_key, stream_config };
        Ok(indexer_service)
    }

    pub async fn run_forever(mut self) -> Result<()> {
        let (config_client, config_stream) = configuration::channel(INDEXING_STREAM_CHUNK_SIZE);

        config_client.send(self.stream_config.clone()).await.context("Sending indexing stream configuration")?;

        let mut stream = ClientBuilder::default()
            .with_bearer_token(Some(self.apibara_api_key.clone()))
            .connect(self.uri.clone())
            .await
            .map_err(|e| anyhow!("Error while connecting to Apibara DNA: {}", e))?
            .start_stream::<Filter, Block, _>(config_stream)
            .await
            .map_err(|e| anyhow!("Error while starting indexing stream: {}", e))?;

        loop {
            match stream.try_next().await {
                Ok(Some(response)) => {
                    self.process_batch(response).await?;
                    self.state
                        .storage
                        .cached_event()
                        .process_cached_events(&self.state.storage.checkpoints(), &self.state.storage.dispatch_events())
                        .await?;
                }
                Ok(None) => continue,
                Err(e) => bail!("Error while streaming indexed batch: {}", e),
            }
        }
    }

    /// Process a batch of blocks indexed by Apibara DNA
    async fn process_batch(&mut self, batch: DataMessage<Block>) -> Result<()> {
        match batch {
            DataMessage::Data { cursor: _, end_cursor: _, finality: _, batch } => {
                for block in batch {
                    for event in block.events.into_iter().filter_map(|e| e.event) {
                        if event.from_address.is_none() {
                            continue;
                        }
                        self.decode_and_store_event(event).await?;
                    }
                }
            }
            DataMessage::Invalidate { cursor } => match cursor {
                Some(c) => bail!("Received an invalidate request data at {}", &c.order_key),
                None => bail!("Invalidate request without cursor provided"),
            },
            DataMessage::Heartbeat => {}
        }
        Ok(())
    }

    /// Decodes a starknet [Event] into either a:
    ///     * [DispatchEvent] and stores it into the events storage,
    ///     * [ValidatorAnnouncementEvent] and stores it into the validators storage.
    async fn decode_and_store_event(&self, event: Event) -> Result<()> {
        let event_selector = event.keys.first().context("No event selector")?;

        match event_selector {
            selector if selector == &*DISPATCH_EVENT_SELECTOR => {
                tracing::info!("Received a DispatchEvent");
                let dispatch_event = DispatchEvent::from_starknet_event_data(event.data.into_iter())
                    .context("Failed to parse DispatchEvent")?;

                tracing::info!("Checking checkpoint storage for correspondence");
                let message_id = dispatch_event.format_message();

                for update in dispatch_event.message.body.updates.iter() {
                    let feed_id = update.feed_id();
                    let dispatch_update_infos = DispatchUpdateInfos {
                        update: update.clone(),
                        emitter_address: dispatch_event.message.header.sender.to_string(),
                        emitter_chain_id: dispatch_event.message.header.origin,
                        nonce: dispatch_event.message.header.nonce,
                    };
                    // Check if there's a corresponding checkpoint
                    if self.state.storage.checkpoints().contains_message_id(message_id).await {
                        tracing::info!("Found corresponding checkpoint for message ID: {:?}", message_id);
                        // If found, store the event directly
                        self.state.storage.dispatch_events().add(feed_id, dispatch_update_infos).await?;
                    } else {
                        tracing::info!("No checkpoint found, caching dispatch event");
                        // If no checkpoint found, add to cache
                        self.state.storage.cached_event().add_event(message_id, &dispatch_event).await;
                    }
                }
            }
            selector if selector == &*VALIDATOR_ANNOUNCEMENT_SELECTOR => {
                tracing::info!("Received a ValidatorAnnouncementEvent");
                let validator_announcement_event =
                    ValidatorAnnouncementEvent::from_starknet_event_data(event.data.into_iter())
                        .context("Failed to parse ValidatorAnnouncementEvent")?;
                self.state.storage.validators().add_from_announcement_event(validator_announcement_event).await?;
            }
            _ => panic!("Unexpected event selector - should never happen."),
        }
        Ok(())
    }
}
