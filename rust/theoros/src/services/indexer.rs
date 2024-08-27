use anyhow::{anyhow, Context, Result};
use apibara_core::{
    node::v1alpha2::DataFinality,
    starknet::v1alpha2::{Block, Event, Filter, HeaderFilter},
};
use apibara_sdk::{configuration, ClientBuilder, Configuration, DataMessage, Uri};
use futures_util::TryStreamExt;
use starknet::core::types::Felt;
use tokio::task::JoinHandle;

use utils::conversions::apibara::felt_as_apibara_field;

use crate::{
    config::Config,
    types::{DispatchEvent, Network},
    AppState,
};

// TODO: depends on the host machine - should be configurable
const INDEXING_STREAM_CHUNK_SIZE: usize = 256;

/// Creates & run the indexer service.
#[tracing::instrument(skip(_config, state))]
pub fn start_indexer_service(network: Network, _config: &Config, state: AppState) -> Result<JoinHandle<Result<()>>> {
    // TODO: retrieve API key from config
    let apibara_api_key = std::env::var("APIBARA_API_KEY")?;

    let handle = tokio::spawn(async move {
        let indexer_service = IndexerService::new(state, network, apibara_api_key);
        // TODO: network should be in the config
        tracing::info!("🧩 Indexer service running for {}!", network);
        indexer_service.start().await.context("😱 Indexer service failed!")
    });
    Ok(handle)
}

#[allow(unused)]
pub struct IndexerService {
    state: AppState,
    network: Network,
    uri: Uri,
    apibara_api_key: String,
    stream_config: Configuration<Filter>,
}

impl IndexerService {
    pub fn new(state: AppState, network: Network, apibara_api_key: String) -> IndexerService {
        // TODO: Should be Pragma X DNA url - see with Apibara team + should be in config
        let uri = Uri::from_static("https://mainnet.starknet.a5a.ch");
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

        IndexerService { state, network, uri, apibara_api_key, stream_config }
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
        self.state.event_storage.add(self.network, dispatch_event);
        Ok(())
    }
}
