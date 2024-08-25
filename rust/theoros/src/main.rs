pub mod config;
pub mod handlers;
pub mod servers;
pub mod services;

use anyhow::Result;
use config::Config;
use deadpool_diesel::postgres::Pool;
use servers::api::run_api_server;
use services::indexer::run_indexer_service;
use tracing::Level;
use utils::{db::init_db_pool, tracing::init_tracing};

use crate::config::config;

const ENV_DATABASE_URL: &str = "PRAGMA_X_INDEXER_DB_URL";

#[allow(unused)]
#[derive(Clone)]
pub struct AppState {
    indexer_pool: Pool,
}

#[tokio::main]
#[tracing::instrument]
async fn main() -> Result<()> {
    dotenvy::dotenv()?;

    init_tracing("theoros", Level::INFO)?;
    let config = config().await;

    // TODO: indexer_db_url should be handled in config()
    let indexer_db_url = std::env::var(ENV_DATABASE_URL)?;
    let indexer_pool = init_db_pool("theoros", &indexer_db_url)?;

    // TODO: metrics
    let state = AppState { indexer_pool };

    start_theorus(config, state).await?;

    // Ensure that the tracing provider is shutdown correctly
    opentelemetry::global::shutdown_tracer_provider();

    Ok(())
}

async fn start_theorus(config: &Config, state: AppState) -> Result<()> {
    let indexer_service = run_indexer_service(config, state.clone());
    let api_server = run_api_server(config, state.clone());

    let (indexer_result, api_result) = tokio::join!(indexer_service, api_server);

    // Handle results
    indexer_result??;
    api_result??;

    Ok(())
}
