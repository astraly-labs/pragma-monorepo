use anyhow::{anyhow, bail, Context, Result};
use apibara_core::{
    node::v1alpha2::DataFinality,
    starknet::v1alpha2::{Block, Event, FieldElement, Filter, HeaderFilter},
};
use apibara_sdk::{configuration, ClientBuilder, Configuration, DataMessage, Uri};
use futures_util::TryStreamExt;
use starknet::core::types::Felt;
use starknet::core::utils::get_selector_from_name;
use tokio::task::JoinSet;

use pragma_utils::{
    conversions::apibara::{apibara_field_as_felt, felt_as_apibara_field},
    services::Service,
};

use crate::types::hyperlane::{DispatchEvent, FromStarknetEventData, ValidatorAnnouncementEvent};
use crate::types::state::AppState;

const INDEXING_STREAM_CHUNK_SIZE: usize = 1;

const START_INDEXER_DELTA: u64 = 5;

lazy_static::lazy_static! {
    // Pragma Dispatcher
    pub static ref DISPATCH_EVENT_SELECTOR: FieldElement = felt_as_apibara_field(&get_selector_from_name("Dispatch").unwrap());
    // Hyperlane mailbox
    pub static ref VALIDATOR_ANNOUNCEMENT_SELECTOR: FieldElement = felt_as_apibara_field(&get_selector_from_name("ValidatorAnnouncement").unwrap());
    // Pragma Feeds Registry
    pub static ref NEW_FEED_ID_EVENT_SELECTOR: FieldElement = felt_as_apibara_field(&get_selector_from_name("NewFeedId").unwrap());
    pub static ref REMOVED_FEED_ID_EVENT_SELECTOR: FieldElement = felt_as_apibara_field(&get_selector_from_name("RemovedFeedId").unwrap());
}

#[derive(Clone)]
pub struct IndexerService {
    state: AppState,
    uri: Uri,
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
    pub fn new(
        state: AppState,
        apibara_uri: Uri,
        hyperlane_mailbox_address: Felt,
        hyperlane_validator_announce_address: Felt,
        pragma_feeds_registry_address: Felt,
        current_block: u64,
    ) -> Result<Self> {
        let stream_config = Configuration::<Filter>::default()
            .with_starting_block(current_block - START_INDEXER_DELTA)
            .with_filter(|mut filter| {
                filter
                    .with_header(HeaderFilter::weak())
                    .add_event(|event| {
                        event
                            .with_from_address(felt_as_apibara_field(&hyperlane_mailbox_address))
                            .with_keys(vec![DISPATCH_EVENT_SELECTOR.clone()])
                    })
                    .add_event(|event| {
                        event
                            .with_from_address(felt_as_apibara_field(&hyperlane_validator_announce_address))
                            .with_keys(vec![VALIDATOR_ANNOUNCEMENT_SELECTOR.clone()])
                    })
                    .add_event(|event| {
                        event
                            .with_from_address(felt_as_apibara_field(&pragma_feeds_registry_address))
                            .with_keys(vec![NEW_FEED_ID_EVENT_SELECTOR.clone(), REMOVED_FEED_ID_EVENT_SELECTOR.clone()])
                    })
                    .build()
            })
            .with_finality(DataFinality::DataStatusPending);

        let indexer_service = Self { state, uri: apibara_uri, stream_config };
        Ok(indexer_service)
    }

    /// Runs the indexer forever.
    pub async fn run_forever(mut self) -> Result<()> {
        let (config_client, config_stream) = configuration::channel(INDEXING_STREAM_CHUNK_SIZE);

        config_client.send(self.stream_config.clone()).await.context("Sending indexing stream configuration")?;

        let mut stream = ClientBuilder::default()
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
                    for event in block.clone().events.into_iter().filter_map(|e| e.event) {
                        if event.from_address.is_none() {
                            continue;
                        }
                        self.process_event(event, &block).await?;
                    }
                }
            }
            DataMessage::Invalidate { cursor } => match cursor {
                Some(c) => bail!("Indexed an invalidate request data at {}", &c.order_key),
                None => bail!("Invalidate request without cursor provided"),
            },
            DataMessage::Heartbeat => {}
        }
        Ok(())
    }

    /// Decodes a starknet [Event].
    async fn process_event(&self, event: Event, block: &Block) -> Result<()> {
        let event_selector = event.keys.first().context("No event selector")?;
        let event_data: Vec<Felt> = event.data.iter().map(apibara_field_as_felt).collect();
        match event_selector {
            selector if selector == &*DISPATCH_EVENT_SELECTOR => {
                self.decode_dispatch_event(event_data, block).await?;
            }
            selector if selector == &*VALIDATOR_ANNOUNCEMENT_SELECTOR => {
                self.decode_validator_announce_event(event_data).await?;
            }
            selector if selector == &*NEW_FEED_ID_EVENT_SELECTOR => {
                self.decode_new_feed_id_event(event_data).await?;
            }
            selector if selector == &*REMOVED_FEED_ID_EVENT_SELECTOR => {
                self.decode_removed_feed_id_event(event_data).await?;
            }
            _ => unreachable!(),
        }
        Ok(())
    }

    /// Decodes a DispatchEvent from the Starknet event data.
    async fn decode_dispatch_event(&self, event_data: Vec<Felt>, block: &Block) -> anyhow::Result<()> {
        let dispatch_event = DispatchEvent::from_starknet_event_data(event_data).context("Parsing DispatchEvent")?;
        let nonce = dispatch_event.message.header.nonce;
        match &block.header {
            Some(h) => {
                tracing::info!(
                    "📨 [Indexer] [Block {}] Indexed a Dispatch event with nonce #{}",
                    h.block_number,
                    nonce,
                );
            }
            None => {
                tracing::info!("📨 [Indexer] Indexed a Dispatch event with nonce #{}", nonce);
            }
        };
        self.state.storage.unsigned_checkpoints().add(nonce, &dispatch_event).await;
        Ok(())
    }

    /// Decodes a ValidatorAnnouncementEvent from the Starknet event data.
    async fn decode_validator_announce_event(&self, event_data: Vec<Felt>) -> anyhow::Result<()> {
        tracing::info!("📨 [Indexer] Indexed a ValidatorAnnouncement event");
        let validator_announcement_event = ValidatorAnnouncementEvent::from_starknet_event_data(event_data)
            .context("Failed to parse ValidatorAnnouncement")?;
        let validators = &mut self.state.storage.validators_fetchers();
        validators.add_from_announcement_event(validator_announcement_event).await?;
        Ok(())
    }

    /// Decodes a NewFeedId event from the Starknet event data.
    async fn decode_new_feed_id_event(&self, event_data: Vec<Felt>) -> anyhow::Result<()> {
        let feed_id = event_data[1].to_hex_string();
        tracing::info!("📨 [Indexer] Indexed a NewFeedId event for: {}", feed_id);
        self.state.storage.feed_ids().add(feed_id).await;
        Ok(())
    }

    /// Decodes a RemovedFeedId event from the Starknet event data.
    async fn decode_removed_feed_id_event(&self, event_data: Vec<Felt>) -> anyhow::Result<()> {
        let feed_id = event_data[1].to_hex_string();
        tracing::info!("📨 [Indexer] Indexed a RemovedFeedId event for: {}", feed_id);
        self.state.storage.feed_ids().remove(&feed_id).await;
        Ok(())
    }
}
