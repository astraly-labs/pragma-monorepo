pub mod config;

use anyhow::Result;
use deadpool_diesel::postgres::Pool;
use utils::{db::init_db_pool, tracing::init_tracing};

#[allow(unused)]
#[derive(Clone)]
pub struct AppState {
    indexer_pool: Pool,
}

#[tokio::main]
#[tracing::instrument]
async fn main() -> Result<()> {
    dotenvy::dotenv()?;

    // TODO: init tracing
    init_tracing("theoros")?;

    // TODO: init config
    let _config = config::init_config();

    // TODO: init database pool
    let indexer_pool = init_db_pool("theoros", "todo: url")?;

    // TODO: metrics

    // TODO: create state
    let _state = AppState { indexer_pool };

    // TODO: start services, i.e indexing + API

    Ok(())
}
