mod config;
mod errors;
mod extractors;
mod handlers;
mod servers;
mod services;
mod types;

use std::sync::Arc;

use anyhow::Result;
use prometheus::Registry;
use tracing::Level;
use utils::tracing::init_tracing;

use crate::{
    config::{config, Config},
    servers::{api::start_api_server, metrics::MetricsServer},
    services::indexer::start_indexer_service,
    types::{EventStorage, Network},
};

// TODO: Config those
const APP_NAME: &str = "theoros";
const LOG_LEVEL: Level = Level::INFO;
const METRICS_PORT: u16 = 8080;
const EVENTS_MEM_SIZE: usize = 10;

#[derive(Clone)]
#[allow(unused)]
pub struct AppState {
    event_storage: Arc<EventStorage>,
    metrics_registry: Registry,
}

#[tokio::main]
#[tracing::instrument]
async fn main() -> Result<()> {
    dotenvy::dotenv()?;
    let config = config().await;
    init_tracing(APP_NAME, LOG_LEVEL)?;

    // Starts all the theoros services
    start_theorus(config).await?;

    // Ensure that the tracing provider is shutdown correctly
    opentelemetry::global::shutdown_tracer_provider();

    Ok(())
}

/// Starts all the Theoros services, i.e:
/// - API server
/// - Indexer services, one for mainnet & testnet
/// - Metrics server
async fn start_theorus(config: &Config) -> Result<()> {
    let metrics = MetricsServer::new(false, METRICS_PORT)?;

    let event_storage = EventStorage::new(EVENTS_MEM_SIZE);
    // TODO: state should contains the rpc_client to interact with a Madara node
    let state = AppState { event_storage: Arc::new(event_storage), metrics_registry: metrics.registry() };

    let mainnet_indexer_handle = start_indexer_service(Network::Mainnet, config, state.clone())?;
    let sepolia_indexer_handle = start_indexer_service(Network::Sepolia, config, state.clone())?;
    let api_handle = start_api_server(config, state.clone())?;
    let metrics_handle = metrics.start()?;

    // TODO: Better struct that groups handles, bubble errors etc...
    let (mainnet_indexer_result, sepolia_indexer_result, api_result, metrics_result) =
        tokio::join!(mainnet_indexer_handle, sepolia_indexer_handle, api_handle, metrics_handle);
    mainnet_indexer_result??;
    sepolia_indexer_result??;
    api_result??;
    metrics_result??;

    Ok(())
}
