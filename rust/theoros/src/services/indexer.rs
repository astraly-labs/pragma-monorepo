use anyhow::{anyhow, Context, Result};
use apibara_core::{
    node::v1alpha2::DataFinality,
    starknet::v1alpha2::{Block, Event, Filter, HeaderFilter},
};
use apibara_sdk::{configuration, ClientBuilder, Configuration, DataMessage, Uri};
use futures_util::TryStreamExt;
use starknet::core::types::Felt;
use tokio::task::JoinHandle;

use utils::conversions::felt_as_apibara_field;

use crate::{config::Config, AppState};

// TODO: depends on the host machine - should be configurable
const INDEXING_STREAM_CHUNK_SIZE: usize = 1024;

/// Creates & run the indexer service.
#[tracing::instrument(skip(_config, _state))]
pub fn run_indexer_service(_config: &Config, _state: AppState) -> Result<JoinHandle<Result<()>>> {
    // TODO: retrieve API key from config
    let apibara_api_key = std::env::var("APIBARA_API_KEY")?;

    let handle = tokio::spawn(async move {
        let indexer_service = IndexerService::new(apibara_api_key);
        tracing::info!("🧩 Indexer service running!");
        indexer_service.start().await.context("😱 Indexer service failed!")
    });
    Ok(handle)
}

#[allow(unused)]
pub struct IndexerService {
    uri: Uri,
    apibara_api_key: String,
    stream_config: Configuration<Filter>,
    reached_pending_block: bool,
}

impl IndexerService {
    pub fn new(apibara_api_key: String) -> IndexerService {
        // TODO: Should be Pragma X DNA url - see with Apibara team + should be in config
        let uri = Uri::from_static("https://mainnet.starknet.a5a.ch");

        // TODO: this should not be a parameter & retrieve from the latest block indexed from the database
        //       for the selected network
        let from_block = 10;
        // TODO: should be a config
        let pragma_oracle_contract = felt_as_apibara_field(&Felt::ZERO);
        // TODO: should be a config
        let dispatch_event_selector = felt_as_apibara_field(&Felt::ZERO);

        let stream_config = Configuration::<Filter>::default()
            .with_starting_block(from_block)
            .with_finality(DataFinality::DataStatusPending)
            .with_filter(|mut filter| {
                filter
                    .with_header(HeaderFilter::weak())
                    .add_event(|event| {
                        event
                            .with_from_address(pragma_oracle_contract.clone())
                            .with_keys(vec![dispatch_event_selector.clone()])
                    })
                    .build()
            });

        IndexerService { uri, apibara_api_key, stream_config, reached_pending_block: false }
    }

    pub async fn start(mut self) -> Result<()> {
        let (config_client, config_stream) = configuration::channel(INDEXING_STREAM_CHUNK_SIZE);

        config_client.send(self.stream_config.clone()).await.unwrap();

        let mut stream = ClientBuilder::default()
            .with_bearer_token(Some(self.apibara_api_key.clone()))
            .connect(self.uri.clone())
            .await
            .unwrap()
            .start_stream::<Filter, Block, _>(config_stream)
            .await
            .unwrap();

        loop {
            match stream.try_next().await {
                Ok(Some(response)) => self.process_batch(response).await?,
                Ok(None) => continue,
                Err(e) => return Err(anyhow!("Error while streaming indexed batch: {}", e)),
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
                    for event in block.events.into_iter().filter_map(|e| e.event) {
                        self.process_dispatch_event(event).await?;
                    }
                }
            }
            DataMessage::Invalidate { cursor } => match cursor {
                Some(c) => {
                    return Err(anyhow!("Received an invalidate request data at {}", &c.order_key));
                }
                None => {
                    return Err(anyhow!("Invalidate request without cursor provided"));
                }
            },
            DataMessage::Heartbeat => {}
        }
        Ok(())
    }

    async fn process_dispatch_event(&self, event: Event) -> Result<()> {
        if event.from_address.is_none() {
            return Ok(());
        }

        // TODO: process the event

        // TODO: store in database

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
            tracing::info!("[🔍 Indexer] 🥳🎉 Reached pending block #{}!", pending_block_number);
        } else {
            tracing::info!("[🔍 Indexer] 🥳🎉 Reached pending block!");
        }
    }
}
