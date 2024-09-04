mod config;
mod errors;
mod extractors;
mod handlers;
mod services;
mod types;

use std::sync::Arc;

use anyhow::Result;
use prometheus::Registry;
use starknet::providers::{jsonrpc::HttpTransport, JsonRpcClient};
use tracing::Level;

use pragma_utils::{
    services::{Service, ServiceGroup},
    tracing::init_tracing,
};
use url::Url;

use crate::{
    config::config,
    services::{ApiService, IndexerService, MetricsService},
    types::EventStorage,
};

// TODO: Config those
const APP_NAME: &str = "theoros";
const LOG_LEVEL: Level = Level::INFO;
const METRICS_PORT: u16 = 8080;

const EVENTS_MEM_SIZE: usize = 10;

const MADARA_RPC_URL: &str = "https://free-rpc.nethermind.io/sepolia-juno";
const APIBARA_DNA_URL: &str = "https://mainnet.starknet.a5a.ch"; // TODO: Should be Pragma X DNA url

#[derive(Clone)]
pub struct AppState {
    pub rpc_client: Arc<JsonRpcClient<HttpTransport>>,
    pub event_storage: Arc<EventStorage>,
    pub metrics_registry: Registry, // already wrapped into an Arc
}

#[tokio::main]
#[tracing::instrument]
async fn main() -> Result<()> {
    dotenvy::dotenv()?;
    let config = config().await;

    init_tracing(APP_NAME, LOG_LEVEL)?;

    let metrics_service = MetricsService::new(false, METRICS_PORT)?;
    let rpc_url: Url = MADARA_RPC_URL.parse()?;
    let rpc_client = JsonRpcClient::new(HttpTransport::new(rpc_url));

    // TODO: state should contains the rpc_client to interact with a Madara node
    let state = AppState {
        rpc_client: Arc::new(rpc_client),
        event_storage: Arc::new(EventStorage::new(EVENTS_MEM_SIZE)),
        metrics_registry: metrics_service.registry(),
    };

    let apibara_api_key = std::env::var("APIBARA_API_KEY")?;
    let indexer_service = IndexerService::new(state.clone(), APIBARA_DNA_URL, apibara_api_key)?;

    let api_service = ApiService::new(state.clone(), config.server_host(), config.server_port());

    let theoros = ServiceGroup::default().with(metrics_service).with(indexer_service).with(api_service);
    theoros.start_and_drive_to_end().await?;

    // Ensure that the tracing provider is shutdown correctly
    opentelemetry::global::shutdown_tracer_provider();

    Ok(())
}
