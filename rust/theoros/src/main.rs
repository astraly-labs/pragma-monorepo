pub mod config;
pub mod servers;
pub mod services;

use anyhow::Result;
use deadpool_diesel::postgres::Pool;
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

    init_tracing("theoros")?;
    let config = config().await;

    let indexer_db_url = std::env::var(ENV_DATABASE_URL)?;
    let indexer_pool = init_db_pool("theoros", &indexer_db_url)?;

    // TODO: metrics
    let state = AppState { indexer_pool };

    tokio::join!(servers::api::run_api_server(config, state));

    // Ensure that the tracing provider is shutdown correctly
    opentelemetry::global::shutdown_tracer_provider();

    Ok(())
}
