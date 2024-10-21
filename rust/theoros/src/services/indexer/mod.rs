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

use crate::{
    storage::DispatchUpdateInfos,
    types::hyperlane::{DispatchEvent, FromStarknetEventData, HasFeedId, ValidatorAnnouncementEvent},
    AppState,
};

const INDEXING_STREAM_CHUNK_SIZE: usize = 256;

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
    reached_pending_block: bool,
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
    ) -> Result<Self> {
        let stream_config = Configuration::<Filter>::default()
            .with_starting_block(9500)
            .with_finality(DataFinality::DataStatusPending)
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
            });

        let indexer_service = Self { state, uri: apibara_uri, stream_config, reached_pending_block: false };
        Ok(indexer_service)
    }

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
                    self.state
                        .storage
                        .cached_events()
                        .process_cached_events(self.state.storage.checkpoints(), self.state.storage.dispatch_events())
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
            DataMessage::Data { cursor: _, end_cursor: _, finality, batch } => {
                if finality == DataFinality::DataStatusPending && !self.reached_pending_block {
                    self.log_pending_block_reached(batch.last());
                    self.reached_pending_block = true;
                }
                for block in batch {
                    match block.header {
                        Some(h) => {
                            tracing::info!("🍱 #{}", h.block_number);
                        },
                        None => {}
                    };
                    for event in block.events.into_iter().filter_map(|e| e.event) {
                        if event.from_address.is_none() {
                            continue;
                        }
                        self.process_event(event).await?;
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
    async fn process_event(&self, event: Event) -> Result<()> {
        let event_selector = event.keys.first().context("No event selector")?;
        let event_data: Vec<Felt> = event.data.iter().map(apibara_field_as_felt).collect();
        match event_selector {
            // Dispatch from the Hyperlane Mailbox
            selector if selector == &*DISPATCH_EVENT_SELECTOR => {
                tracing::info!("📨 [Indexer] Received a Dispatch event");
                let dispatch_event =
                    DispatchEvent::from_starknet_event_data(event_data).context("Failed to parse Dispatch")?;
                let message_id = dispatch_event.id();

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
                        tracing::debug!("No checkpoint found, caching dispatch event");
                        // If no checkpoint found, add to cache
                        self.state.storage.cached_events().add(message_id, &dispatch_event).await;
                    }
                }
            }
            // Validator Announcement from the Hyperlane Validator Announce contract
            selector if selector == &*VALIDATOR_ANNOUNCEMENT_SELECTOR => {
                tracing::info!("📨 [Indexer] Received a ValidatorAnnouncement event");
                let validator_announcement_event = ValidatorAnnouncementEvent::from_starknet_event_data(event_data)
                    .context("Failed to parse ValidatorAnnouncement")?;
                self.state.storage.validators().add_from_announcement_event(validator_announcement_event).await?;
            }
            // Add feed id from the Pragma Feeds Registry
            selector if selector == &*NEW_FEED_ID_EVENT_SELECTOR => {
                let feed_id = event_data[1].to_hex_string();
                tracing::info!("📨 [Indexer] Received a NewFeedId event for: {}", feed_id);
                self.state.storage.feed_ids().add(feed_id).await;
            }
            // Remove feed id from the Pragma Feeds Registry
            selector if selector == &*REMOVED_FEED_ID_EVENT_SELECTOR => {
                let feed_id = event_data[1].to_hex_string();
                tracing::info!("📨 [Indexer] Received a RemovedFeedId event for: {}", feed_id);
                self.state.storage.feed_ids().remove(&feed_id).await;
            }
            _ => panic!("😱 Unexpected event selector - should never happen."),
        }
        Ok(())
    }

    /// Logs that we successfully reached current pending block
    fn log_pending_block_reached(&self, last_block_in_batch: Option<&Block>) {
        let maybe_pending_block_number = if let Some(last_block) = last_block_in_batch {
            last_block.header.as_ref().map(|header| header.block_number)
        } else {
            None
        };

        if let Some(pending_block_number) = maybe_pending_block_number {
            tracing::info!(
                "[🔍 Indexer] 🥳🎉 Reached pending block #{}!",
                pending_block_number
            );
        } else {
            tracing::info!("[🔍 Indexer] 🥳🎉 Reached pending block!",);
        }
    }
}
