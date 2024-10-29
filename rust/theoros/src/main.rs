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

use std::sync::{atomic::AtomicUsize, Arc};

use anyhow::Result;
use clap::Parser;
use prometheus::Registry;
use storage::TheorosStorage;
use tokio::sync::watch;
use tracing::Level;

use pragma_utils::{
    services::{Service, ServiceGroup},
    tracing::init_tracing,
};

use cli::TheorosCli;
use rpc::{evm::HyperlaneValidatorsMapping, starknet::StarknetRpc};
use services::{ApiService, HyperlaneService, IndexerService, MetricsService};

const LOG_LEVEL: Level = Level::INFO;

pub struct AppState {
    pub starknet_rpc: Arc<StarknetRpc>,
    pub hyperlane_validators_mapping: Arc<HyperlaneValidatorsMapping>,
    pub storage: Arc<TheorosStorage>,
    pub metrics_registry: Registry, // already wrapped into an Arc
    pub ws: Arc<WsState>,
}

pub struct WsState {
    pub subscriber_counter: AtomicUsize,
}

#[allow(clippy::new_without_default)]
impl WsState {
    pub fn new() -> Self {
        Self { subscriber_counter: AtomicUsize::new(0) }
    }
}

impl Clone for AppState {
    fn clone(&self) -> Self {
        Self {
            starknet_rpc: self.starknet_rpc.clone(),
            hyperlane_validators_mapping: self.hyperlane_validators_mapping.clone(),
            storage: self.storage.clone(),
            metrics_registry: self.metrics_registry.clone(),
            ws: self.ws.clone(),
        }
    }
}

lazy_static::lazy_static! {
    /// A static exit flag to indicate to running threads that we're shutting down. This is used to
    /// gracefully shut down the application.
    ///
    /// We make this global based such that:
    /// - It's easy to access from anywhere in the application.
    /// - No need to carefully pass it around.
    /// - Sender does not require an async context to operate.
    /// - All receivers will be notified when the flag is set.
    pub static ref EXIT: watch::Sender<bool> = watch::channel(false).0;
}

#[tokio::main]
#[tracing::instrument]
async fn main() -> Result<()> {
    let config = TheorosCli::parse();

    init_tracing(&config.app_name, LOG_LEVEL)?;

    let starknet_rpc = StarknetRpc::new(config.madara_rpc_url);
    let hyperlane_rpcs = HyperlaneValidatorsMapping::from_config(&config.evm_config).await?;

    let (update_tx, _) = tokio::sync::broadcast::channel(1000);

    let theoros_storage = TheorosStorage::from_rpc_state(
        &starknet_rpc,
        &config.pragma_feeds_registry_address,
        &config.hyperlane_validator_announce_address,
        update_tx,
    )
    .await?;

    let metrics_service = MetricsService::new(false, config.metrics_port)?;

    let state = AppState {
        starknet_rpc: Arc::new(starknet_rpc),
        hyperlane_validators_mapping: Arc::new(hyperlane_rpcs),
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
