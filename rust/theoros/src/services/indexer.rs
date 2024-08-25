use std::sync::Arc;

use anyhow::Result;
use apibara_core::{
    node::v1alpha2::DataFinality,
    starknet::v1alpha2::{Block, Filter, HeaderFilter},
};
use apibara_sdk::{configuration, ClientBuilder, Configuration, Uri};
use futures_util::TryStreamExt;
use starknet::core::types::Felt;
use starknet::providers::{jsonrpc::HttpTransport, JsonRpcClient};
use url::Url;

use utils::conversions::felt_as_apibara_field;

use crate::{config::Config, AppState};

// TODO: depends on the host machine - should be configurable
const INDEXING_STREAM_CHUNK_SIZE: usize = 1024;

/// Creates & run the indexer service.
pub async fn run_indexer_service(_config: &Config, _state: &AppState) {
    // TODO: retrieve all these parameters from the config
    let rpc_url: Url = "".parse().unwrap();
    let rpc_client = Arc::new(JsonRpcClient::new(HttpTransport::new(rpc_url)));
    let apibara_api_key = String::new();
    let from_block = 0;

    let indexer_service = IndexerService::new(rpc_client, apibara_api_key, from_block);
    tracing::info!("🚀 Indexer service started");
    tokio::spawn(async move { indexer_service.start().await.unwrap() });
}

pub struct IndexerService {
    uri: Uri,
    #[allow(unused)]
    rpc_client: Arc<JsonRpcClient<HttpTransport>>,
    apibara_api_key: String,
    stream_config: Configuration<Filter>,
}

impl IndexerService {
    pub fn new(
        rpc_client: Arc<JsonRpcClient<HttpTransport>>,
        apibara_api_key: String,
        from_block: u64,
    ) -> IndexerService {
        // TODO: Should be Pragma X URL - see with Apibara team
        let uri = Uri::from_static("https://mainnet.starknet.a5a.ch");

        let stream_config = Configuration::<Filter>::default()
            .with_starting_block(from_block)
            .with_finality(DataFinality::DataStatusPending)
            .with_filter(|mut filter| {
                filter
                    .with_header(HeaderFilter::weak())
                    .add_event(|event| {
                        // TODO: update the addresses to the right ones
                        event
                            .with_from_address(felt_as_apibara_field(&Felt::ZERO))
                            .with_keys(vec![felt_as_apibara_field(&Felt::ZERO)])
                    })
                    .build()
            });

        IndexerService { rpc_client, uri, apibara_api_key, stream_config }
    }

    /// Retrieve all the ModifyPosition events emitted from the Vesu Singleton Contract.
    pub async fn start(self) -> Result<()> {
        let (config_client, config_stream) = configuration::channel(INDEXING_STREAM_CHUNK_SIZE);

        let mut reached_pending_block: bool = false;

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
                Ok(Some(response)) => match response {
                    apibara_sdk::DataMessage::Data { cursor: _, end_cursor: _, finality, batch } => {
                        if finality == DataFinality::DataStatusPending && !reached_pending_block {
                            self.log_pending_block_reached(batch.last());
                            reached_pending_block = true;
                        }
                        for block in batch {
                            // TODO: use indexed events
                            for _event in block.events {}
                        }
                    }
                    apibara_sdk::DataMessage::Invalidate { cursor } => match cursor {
                        Some(c) => {
                            return Err(anyhow::anyhow!("Received an invalidate request data at {}", &c.order_key));
                        }
                        None => {
                            return Err(anyhow::anyhow!("Invalidate request without cursor provided"));
                        }
                    },
                    apibara_sdk::DataMessage::Heartbeat => {}
                },
                Ok(None) => continue,
                Err(e) => {
                    return Err(anyhow::anyhow!("Error while streaming: {}", e));
                }
            }
        }
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
            tracing::info!("[🔍 Indexer] 🥳🎉 Reached pending block!",);
        }
    }
}
