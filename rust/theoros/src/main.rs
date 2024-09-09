mod errors;
mod extractors;
mod handlers;
mod services;
mod storages;
mod types;

use std::sync::Arc;

use anyhow::{Context, Result};
use prometheus::Registry;
use storages::TheorosStorage;
use tracing::Level;

use pragma_utils::{
    services::{Service, ServiceGroup},
    tracing::init_tracing,
};
use types::StarknetRpc;
use url::Url;

use crate::services::{ApiService, IndexerService, MetricsService};

// TODO: Everything below here should be configurable, either via CLI or config file.
// See: https://github.com/astraly-labs/pragma-monorepo/issues/17
const APP_NAME: &str = "theoros";
const LOG_LEVEL: Level = Level::INFO;
const METRICS_PORT: u16 = 8080;

const MADARA_RPC_URL: &str = "https://free-rpc.nethermind.io/sepolia-juno";
const APIBARA_DNA_URL: &str = "https://sepolia.starknet.a5a.ch"; // TODO: Should be Pragma X DNA url

const SERVER_HOST: &str = "0.0.0.0";
const SERVER_PORT: u16 = 3000;

// TODO: Do we want to have data_feeds list? Does it cost more to have all feeds?
lazy_static::lazy_static! {
    pub static ref DATA_FEEDS: Vec<u16> = vec![
        1, 2, 3, 4,
    ];
}

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

    let rpc_url: Url = MADARA_RPC_URL.parse()?;
    let metrics_service = MetricsService::new(false, METRICS_PORT)?;

    let state = AppState {
        rpc_client: Arc::new(StarknetRpc::new(rpc_url)),
        storage: Arc::new(TheorosStorage::default()),
        metrics_registry: metrics_service.registry(),
    };

    // TODO: Initial RPC calls to populate the Storage

    let apibara_api_key = std::env::var("APIBARA_API_KEY").context("APIBARA_API_KEY not found.")?;
    let indexer_service = IndexerService::new(state.clone(), APIBARA_DNA_URL, apibara_api_key)?;

    let api_service = ApiService::new(state.clone(), SERVER_HOST, SERVER_PORT);

    let theoros = ServiceGroup::default().with(metrics_service).with(indexer_service).with(api_service);
    theoros.start_and_drive_to_end().await?;

    // Ensure that the tracing provider is shutdown correctly
    opentelemetry::global::shutdown_tracer_provider();

    Ok(())
}
