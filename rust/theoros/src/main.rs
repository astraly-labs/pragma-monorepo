mod cli;
mod configs;
mod constants;
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
use storage::TheorosStorage;
use tracing::Level;

use pragma_utils::{
    services::{Service, ServiceGroup},
    tracing::init_tracing,
};

use cli::TheorosCli;
use rpc::{evm::HyperlaneValidatorsMapping, starknet::StarknetRpc};
use services::{ApiService, HyperlaneService, IndexerService, MetricsService};
use types::state::{AppState, WsState};

const LOG_LEVEL: Level = Level::INFO;

#[tokio::main]
#[tracing::instrument]
async fn main() -> Result<()> {
    let config = TheorosCli::parse();

    init_tracing(&config.app_name, LOG_LEVEL)?;

    let starknet_rpc = StarknetRpc::new(config.madara_rpc_url);
    let hyperlane_validators_mapping = HyperlaneValidatorsMapping::from_config(&config.evm_config).await?;

    let theoros_storage = TheorosStorage::from_rpc_state(
        &starknet_rpc,
        &config.pragma_feeds_registry_address,
        &config.hyperlane_validator_announce_address,
    )
    .await?;

    let metrics_service = MetricsService::new(false, config.metrics_port)?;

    let state = AppState {
        starknet_rpc: Arc::new(starknet_rpc),
        hyperlane_validators_mapping: Arc::new(hyperlane_validators_mapping),
        storage: Arc::new(theoros_storage),
        metrics_registry: metrics_service.registry(),
        ws: Arc::new(WsState::new()),
    };

    let indexer_service = IndexerService::new(
        state.clone(),
        config.apibara_dna_uri,
        config.hyperlane_mailbox_address,
        config.hyperlane_validator_announce_address,
        config.pragma_feeds_registry_address,
        state.starknet_rpc.block_number().await?,
    )?;
    let hyperlane_service = HyperlaneService::new(state.storage.clone());
    let api_service = ApiService::new(state.clone(), &config.server_host, config.server_port);

    ServiceGroup::default()
        .with(metrics_service)
        .with(indexer_service)
        .with(hyperlane_service)
        .with(api_service)
        .start_and_drive_to_end()
        .await?;

    // Ensure that the tracing provider is shutdown correctly
    opentelemetry::global::shutdown_tracer_provider();

    Ok(())
}
