mod config;
mod errors;
mod extractors;
mod handlers;
mod infra;
mod servers;
mod services;
mod types;

use anyhow::Result;
use deadpool_diesel::postgres::Pool;
use prometheus::Registry;
use tracing::Level;
use utils::{db::init_db_pool, tracing::init_tracing};

use crate::{
    config::{config, Config},
    servers::{api::start_api_server, metrics::MetricsServer},
    services::indexer::start_indexer_service,
};

// TODO: Config those
const APP_NAME: &str = "theoros";
const LOG_LEVEL: Level = Level::INFO;
const ENV_DATABASE_URL: &str = "INDEXER_DB_URL";
const METRICS_PORT: u16 = 8080;

#[derive(Clone)]
#[allow(unused)]
pub struct AppState {
    indexer_pool: Pool,
    metrics_registry: Registry,
}

#[tokio::main]
#[tracing::instrument]
async fn main() -> Result<()> {
    dotenvy::dotenv()?;
    let config = config().await;
    init_tracing(APP_NAME, LOG_LEVEL)?;

    // TODO: indexer_db_url should be handled in config()
    let database_url = std::env::var(ENV_DATABASE_URL)?;
    let indexer_pool = init_db_pool(APP_NAME, &database_url)?;
    infra::db::migrations::run_migrations(&indexer_pool).await?;

    start_theorus(config, indexer_pool).await?;

    // Ensure that the tracing provider is shutdown correctly
    opentelemetry::global::shutdown_tracer_provider();

    Ok(())
}

/// Starts all the Theoros services, i.e:
/// - API server
/// - Indexer service
/// - Metrics server
async fn start_theorus(config: &Config, indexer_pool: Pool) -> Result<()> {
    let metrics = MetricsServer::new(false, METRICS_PORT)?;

    // TODO: state should contains the rpc_client to interact with a Madara node
    let state = AppState { indexer_pool, metrics_registry: metrics.registry() };

    // TODO: spawn one indexer for mainnet & one for testnet
    let indexer_handle = start_indexer_service(config, state.clone())?;
    let api_handle = start_api_server(config, state.clone())?;
    let metrics_handle = metrics.start()?;

    // TODO: Better struct that groups handles, bubble errors etc...
    let (indexer_result, api_result, metrics_result) = tokio::join!(indexer_handle, api_handle, metrics_handle);
    indexer_result??;
    api_result??;
    metrics_result??;

    Ok(())
}
