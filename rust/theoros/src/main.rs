mod config;
mod handlers;
mod servers;
mod services;

use anyhow::Result;
use deadpool_diesel::postgres::Pool;
use tracing::Level;
use utils::{db::init_db_pool, tracing::init_tracing};

use crate::{
    config::{config, Config},
    servers::api::run_api_server,
    services::indexer::run_indexer_service,
};

const APP_NAME: &str = "theoros";
const ENV_DATABASE_URL: &str = "PRAGMA_X_INDEXER_DB_URL";

#[derive(Clone)]
pub struct AppState {
    #[allow(unused)]
    indexer_pool: Pool,
}

#[tokio::main]
#[tracing::instrument]
async fn main() -> Result<()> {
    dotenvy::dotenv()?;
    init_tracing(APP_NAME, Level::INFO)?;
    let config = config().await;

    // TODO: indexer_db_url should be handled in config()
    let indexer_pool = init_db_pool(APP_NAME, &std::env::var(ENV_DATABASE_URL)?)?;

    let state = AppState { indexer_pool };

    // TODO: metrics
    start_theorus(config, state).await?;

    // Ensure that the tracing provider is shutdown correctly
    opentelemetry::global::shutdown_tracer_provider();

    Ok(())
}

async fn start_theorus(config: &Config, state: AppState) -> Result<()> {
    // TODO: spawn one indexer for mainnet & one for testnet?
    let indexer_service = run_indexer_service(config, state.clone())?;
    let api_server = run_api_server(config, state.clone())?;

    let (indexer_result, api_result) = tokio::join!(indexer_service, api_server);

    // Handle results
    indexer_result??;
    api_result??;

    Ok(())
}
