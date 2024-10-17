mod cli;
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
use clap::Parser;
use prometheus::Registry;
use storage::TheorosStorage;
use tracing::Level;

use pragma_utils::{
    services::{Service, ServiceGroup},
    tracing::init_tracing,
};

use cli::TheorosCli;
use rpc::{PragmaDispatcherCalls, StarknetRpc};
use services::{ApiService, HyperlaneService, IndexerService, MetricsService};

const LOG_LEVEL: Level = Level::INFO;

#[derive(Clone)]
pub struct AppState {
    pub rpc_client: Arc<StarknetRpc>,
    pub storage: Arc<TheorosStorage>,
    pub metrics_registry: Registry, // already wrapped into an Arc
}

#[tokio::main]
#[tracing::instrument]
async fn main() -> Result<()> {
    let config = TheorosCli::parse();

    init_tracing(&config.app_name, LOG_LEVEL)?;

    let rpc_client = StarknetRpc::new(config.madara_rpc_url);

    let pragma_feed_registry_address = rpc_client
        .get_pragma_feed_registry_address(&config.pragma_dispatcher_address)
        .await
        .context("Fetching the Pragma Feed Registry address")?;

    let theoros_storage = TheorosStorage::from_rpc_state(
        &rpc_client,
        &pragma_feed_registry_address,
        &config.hyperlane_validator_announce_address,
    )
    .await?;

    let metrics_service = MetricsService::new(false, config.metrics_port)?;

    let state = AppState {
        rpc_client: Arc::new(rpc_client),
        storage: Arc::new(theoros_storage),
        metrics_registry: metrics_service.registry(),
    };

    let indexer_service = IndexerService::new(
        state.clone(),
        config.apibara_dna_uri,
        config.hyperlane_mailbox_address,
        config.hyperlane_validator_announce_address,
        pragma_feed_registry_address,
    )?;
    let api_service = ApiService::new(state.clone(), &config.server_host, config.server_port);
    let hyperlane_service = HyperlaneService::new(state.clone(), config.hyperlane_merkle_tree_hook_address);

    let theoros =
        ServiceGroup::default().with(metrics_service).with(indexer_service).with(api_service).with(hyperlane_service);

    theoros.start_and_drive_to_end().await?;

    // Ensure that the tracing provider is shutdown correctly
    opentelemetry::global::shutdown_tracer_provider();
    Ok(())
}
