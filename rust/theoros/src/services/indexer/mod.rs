use std::str::FromStr;

use anyhow::{anyhow, Context, Result};
use apibara_core::{
    node::v1alpha2::DataFinality,
    starknet::v1alpha2::{Block, Event, Filter, HeaderFilter},
};
use apibara_sdk::{configuration, ClientBuilder, Configuration, DataMessage, Uri};
use futures_util::TryStreamExt;
use starknet::core::types::Felt;
use tokio::task::JoinSet;

use pragma_utils::{conversions::apibara::felt_as_apibara_field, services::Service};

use crate::{types::DispatchEvent, AppState};

// TODO: depends on the host machine - should be configurable
const INDEXING_STREAM_CHUNK_SIZE: usize = 256;

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
        // TODO: should be a config
        let pragma_oracle_contract = felt_as_apibara_field(&Felt::ZERO);
        // TODO: should be a config
        let dispatch_event_selector = felt_as_apibara_field(&Felt::ZERO);

        let stream_config = Configuration::<Filter>::default()
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
                Ok(Some(response)) => self.process_batch(response).await?,
                Ok(None) => continue,
                Err(e) => return Err(anyhow!("Error while streaming indexed batch: {}", e)),
            }
        }
    }

    /// Process a batch of blocks indexed by Apibara DNA
    async fn process_batch(&mut self, batch: DataMessage<Block>) -> Result<()> {
        match batch {
            DataMessage::Data { cursor: _, end_cursor: _, finality: _, batch } => {
                for block in batch {
                    for event in block.events.into_iter().filter_map(|e| e.event) {
                        self.decode_and_store_event(event).await?;
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

    async fn decode_and_store_event(&self, event: Event) -> Result<()> {
        if event.from_address.is_none() {
            return Ok(());
        }
        let dispatch_event = DispatchEvent::from_event_data(event.data)?;
        self.state.event_storage.add(dispatch_event);
        Ok(())
    }
}
