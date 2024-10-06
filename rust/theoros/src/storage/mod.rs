pub mod cache;
pub mod event;
pub mod validators;

use crate::storage::cache::EventCache;
pub use event::*;
use std::collections::HashSet;
pub use validators::*;

use starknet::core::types::Felt;

use crate::rpc::{HyperlaneCalls, PragmaWrapperCalls, StarknetRpc};

/// Theoros storage that contains:
///   * a set of all available data feeds,
///   * a mapping of all the validators and their fetchers.
///   * a mapping of all the validators and their latest fetched checkpoints.
///   * an events storage containing the most recents [DispatchEvent] events indexed,
#[derive(Default)]
pub struct TheorosStorage {
    data_feeds: HashSet<String>,
    validators: ValidatorStorage,
    checkpoints: ValidatorCheckpointStorage,
    cached_events: EventCache,
    dispatch_events: EventStorage,
}

impl TheorosStorage {
    // TODO: remove this later, only used for now for tests
    pub fn testing_state() -> Self {
        let constants_data_feeds: HashSet<String> = HashSet::from([
            "0x01534d4254432f555344".into(),     // SPOT MEDIAN: BTC/USD
            "0x01534d4554482f555344".into(),     // SPOT MEDIAN: ETH/USD
            "0x014F50454b55424f2f555344".into(), // OPTIONS: EKUBO/USD
        ]);
        Self { data_feeds: constants_data_feeds, ..Default::default() }
    }

    pub async fn from_rpc_state(
        rpc_client: &StarknetRpc,
        pragma_wrapper_address: &Felt,
        hyperlane_address: &Felt,
    ) -> anyhow::Result<Self> {
        let mut theoros_storage = TheorosStorage::default();

        let initial_validators = rpc_client.get_announced_validators(hyperlane_address).await?;
        let initial_locations =
            rpc_client.get_announced_storage_locations(hyperlane_address, &initial_validators).await?;
        theoros_storage.validators.fill_with_initial_state(initial_validators, initial_locations).await?;

        let supported_data_feeds = rpc_client.get_data_feeds(pragma_wrapper_address).await?;
        theoros_storage.data_feeds = supported_data_feeds.into_iter().collect();
        Ok(theoros_storage)
    }

    pub fn data_feeds(&self) -> &HashSet<String> {
        &self.data_feeds
    }

    pub fn validators(&self) -> &ValidatorStorage {
        &self.validators
    }

    pub fn checkpoints(&self) -> &ValidatorCheckpointStorage {
        &self.checkpoints
    }

    pub fn dispatch_events(&self) -> &EventStorage {
        &self.dispatch_events
    }

    pub fn cached_event(&self) -> &EventCache {
        &self.cached_events
    }
}
