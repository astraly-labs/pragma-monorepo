use std::sync::{atomic::AtomicUsize, Arc};

use prometheus::Registry;

use crate::{
    rpc::{evm::HyperlaneValidatorsMapping, starknet::StarknetRpc},
    storage::TheorosStorage,
};

#[derive(Clone)]
pub struct AppState {
    pub starknet_rpc: Arc<StarknetRpc>,
    pub hyperlane_validators_mapping: Arc<HyperlaneValidatorsMapping>,
    pub storage: Arc<TheorosStorage>,
    #[allow(unused)]
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
