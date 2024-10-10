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

const PRAGMA_WRAPPER_CONTRACT_ADDRESS: Felt =
    Felt::from_hex_unchecked("0x42d0ccae2cd3647df3bf9379d74efc93851370b12338a5aa6a676e381396b5");
const HYPERLANE_CORE_CONTRACT_ADDRESS: Felt =
    Felt::from_hex_unchecked("0x41c20175af14a0bfebfc9ae2f3bda29230a0bceb551844197d9f46faf76d6da");
const HYPERLANE_MERKLE_TREE_HOOK_ADDRESS: Felt =
    Felt::from_hex_unchecked("0xb9a75496355e223652c40fe50d45b5f39b86d3cc5c4f7aed44be6c7f6a8b4c");

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
        TheorosStorage::from_rpc_state(&rpc_client, &PRAGMA_WRAPPER_CONTRACT_ADDRESS, &HYPERLANE_CORE_CONTRACT_ADDRESS)
            .await?;
    // let theoros_storage = TheorosStorage::testing_state();

    // Theoros metrics
    let metrics_service = MetricsService::new(false, METRICS_PORT)?;

    let state = AppState {
        rpc_client: Arc::new(rpc_client),
        storage: Arc::new(theoros_storage),
        metrics_registry: metrics_service.registry(),
    };

    let apibara_api_key = std::env::var("APIBARA_API_KEY").context("APIBARA_API_KEY not found.")?;
    let indexer_service = IndexerService::new(state.clone(), APIBARA_DNA_URL, apibara_api_key)?;

    let api_service = ApiService::new(state.clone(), SERVER_HOST, SERVER_PORT);

    let hyperlane_service = HyperlaneService::new(state.clone(), HYPERLANE_MERKLE_TREE_HOOK_ADDRESS);

    let theoros =
        ServiceGroup::default().with(metrics_service).with(indexer_service).with(api_service).with(hyperlane_service);
    theoros.start_and_drive_to_end().await?;

    // Ensure that the tracing provider is shutdown correctly
    opentelemetry::global::shutdown_tracer_provider();

    Ok(())
}
