mod cli;
mod configs;
mod errors;
mod extractors;
mod handlers;
mod rpc;
mod services;
mod storage;
mod types;

use std::sync::Arc;

use anyhow::Result;
use clap::Parser;
use prometheus::Registry;
use storage::TheorosStorage;
use tracing::Level;

use pragma_utils::{
    services::{Service, ServiceGroup},
    tracing::init_tracing,
};

use cli::TheorosCli;
use rpc::{evm::HyperlaneRpcsMapping, starknet::StarknetRpc};
use services::{ApiService, HyperlaneService, IndexerService, MetricsService};

const LOG_LEVEL: Level = Level::INFO;

#[derive(Clone)]
pub struct AppState {
    pub starknet_rpc: Arc<StarknetRpc>,
    pub evm_hyperlane_rpcs_mapping: Arc<HyperlaneRpcsMapping>,
    pub storage: Arc<TheorosStorage>,
    pub metrics_registry: Registry, // already wrapped into an Arc
}

#[tokio::main]
#[tracing::instrument]
async fn main() -> Result<()> {
    let config = TheorosCli::parse();

    init_tracing(&config.app_name, LOG_LEVEL)?;

    let starknet_rpc = StarknetRpc::new(config.madara_rpc_url);
    let hyperlane_rpcs = HyperlaneRpcsMapping::from_config(&config.evm_config).await?;

    let theoros_storage = TheorosStorage::from_rpc_state(
        &starknet_rpc,
        &config.pragma_feeds_registry_address,
        &config.hyperlane_validator_announce_address,
    )
    .await?;

    let metrics_service = MetricsService::new(false, config.metrics_port)?;

    let state = AppState {
        starknet_rpc: Arc::new(starknet_rpc),
        evm_hyperlane_rpcs_mapping: Arc::new(hyperlane_rpcs),
        storage: Arc::new(theoros_storage),
        metrics_registry: metrics_service.registry(),
    };

    let indexer_service = IndexerService::new(
        state.clone(),
        config.apibara_dna_uri,
        config.hyperlane_mailbox_address,
        config.hyperlane_validator_announce_address,
        config.pragma_feeds_registry_address,
        config.indexer_starting_block,
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
