mod errors;
mod extractors;
mod handlers;
mod hyperlane;
mod rpc;
mod services;
mod storage;
mod types;

use std::sync::Arc;

use anyhow::{Context, Result};
use prometheus::Registry;
use starknet::core::types::Felt;
use storage::TheorosStorage;
use tracing::Level;
use url::Url;

use pragma_utils::{
    services::{Service, ServiceGroup},
    tracing::init_tracing,
};

use rpc::StarknetRpc;
use services::{ApiService, HyperlaneService, IndexerService, MetricsService};

// TODO: Everything below here should be configurable, either via CLI  or config file.
// See: https://github.com/astraly-labs/pragma-monorepo/issues/17
const APP_NAME: &str = "theoros";
const LOG_LEVEL: Level = Level::INFO;
const METRICS_PORT: u16 = 8080;

const MADARA_RPC_URL: &str = "https://madara-pragma-prod.karnot.xyz/";
const APIBARA_DNA_URL: &str = "https://devnet.pragma.a5a.ch";

const SERVER_HOST: &str = "0.0.0.0";
const SERVER_PORT: u16 = 3000;

const PRAGMA_DISPATCHER_CONTRACT_ADDRESS: Felt =
    Felt::from_hex_unchecked("0x04d997c57f63d509f483927ce74135a4e12de834144d9e90044ac03f6024267e");
const HYPERLANE_CORE_CONTRACT_ADDRESS: Felt =
    Felt::from_hex_unchecked("0x05bfb1a565a1fa2eb33c5d8e587a7aeb5e6846d3aadf9fecb529ace1e3457096");
const HYPERLANE_MERKLE_TREE_HOOK_ADDRESS: Felt =
    Felt::from_hex_unchecked("0x01520c48d7aced426c41e8b71587add7fb64c9945115d3ea677a49f45ddf81e3");

const HYPERLANE_VALIDATOR_ANNOUNCE: Felt =
    Felt::from_hex_unchecked("0x0022245997c5f4f5e6eb13764be91de00b4299147ce7f516dbad925c7aeb69d3");

#[derive(Clone)]
pub struct AppState {
    pub rpc_client: Arc<StarknetRpc>,
    pub storage: Arc<TheorosStorage>,
    pub metrics_registry: Registry, // already wrapped into an Arc
}

#[tokio::main]
#[tracing::instrument]
async fn main() -> Result<()> {
    init_tracing(APP_NAME, LOG_LEVEL)?;

    // New RPC client
    let rpc_url: Url = MADARA_RPC_URL.parse()?;
    let rpc_client = StarknetRpc::new(rpc_url);

    // New storage + initialization
    let theoros_storage =
        TheorosStorage::from_rpc_state(&rpc_client, &PRAGMA_DISPATCHER_CONTRACT_ADDRESS, &HYPERLANE_VALIDATOR_ANNOUNCE)
            .await?;
    // let theoros_storage = TheorosStorage::testing_state();

    // Theoros metrics
    let metrics_service = MetricsService::new(false, METRICS_PORT)?;

    let state = AppState {
        rpc_client: Arc::new(rpc_client),
        storage: Arc::new(theoros_storage),
        metrics_registry: metrics_service.registry(),
    };

    let indexer_service = IndexerService::new(state.clone(), APIBARA_DNA_URL)?;

    let api_service = ApiService::new(state.clone(), SERVER_HOST, SERVER_PORT);

    let hyperlane_service = HyperlaneService::new(state.clone(), HYPERLANE_MERKLE_TREE_HOOK_ADDRESS);

    let theoros =
        ServiceGroup::default().with(metrics_service).with(indexer_service).with(api_service).with(hyperlane_service);
    theoros.start_and_drive_to_end().await?;

    // Ensure that the tracing provider is shutdown correctly
    opentelemetry::global::shutdown_tracer_provider();

    Ok(())
}
