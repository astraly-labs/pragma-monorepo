mod config;
mod errors;
mod extractors;
mod handlers;
mod services;
mod types;

use std::sync::Arc;

use anyhow::Result;
use prometheus::Registry;
use tracing::Level;
use utils::tracing::init_tracing;

use crate::{
    config::config,
    services::{ApiService, IndexerService, MetricsService, Service, ServiceGroup},
    types::EventStorage,
};

// TODO: Config those
const APP_NAME: &str = "theoros";
const LOG_LEVEL: Level = Level::INFO;
const EVENTS_MEM_SIZE: usize = 10;
const METRICS_PORT: u16 = 8080;

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

    let metrics_service = MetricsService::new(false, METRICS_PORT)?;

    let event_storage = EventStorage::new(EVENTS_MEM_SIZE);
    // TODO: state should contains the rpc_client to interact with a Madara node
    let state = AppState { event_storage: Arc::new(event_storage), metrics_registry: metrics_service.registry() };

    // TODO: key in config
    let apibara_api_key = std::env::var("APIBARA_API_KEY")?;
    let indexer_service = IndexerService::new(state.clone(), apibara_api_key);
    let api_service = ApiService::new(state.clone(), config.server_host(), config.server_port());

    let theoros = ServiceGroup::default().with(metrics_service).with(indexer_service).with(api_service);
    theoros.start_and_drive_to_end().await?;

    // Ensure that the tracing provider is shutdown correctly
    opentelemetry::global::shutdown_tracer_provider();

    Ok(())
}
