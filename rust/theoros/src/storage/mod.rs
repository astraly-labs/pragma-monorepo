pub mod cache;
pub mod event;
pub mod validators;

use crate::storage::cache::EventCache;
pub use event::*;
use std::collections::HashSet;
pub use validators::*;

use starknet::core::types::Felt;

use crate::rpc::{HyperlaneCalls, PragmaDispatcherCalls, StarknetRpc};

/// Theoros storage that contains:
///   * a set of all available feed ids,
///   * a mapping of all the validators and their fetchers.
///   * a mapping of all the validators and their latest fetched checkpoints.
///   * an event cache,
///   * an events storage containing the most recents [DispatchEvent] events indexed.
#[derive(Default)]
pub struct TheorosStorage {
    feed_ids: HashSet<String>,
    validators: ValidatorStorage,
    checkpoints: ValidatorCheckpointStorage,
    cached_events: EventCache,
    dispatch_events: EventStorage,
}

impl TheorosStorage {
    pub async fn from_rpc_state(
        rpc_client: &StarknetRpc,
        pragma_dispatcher_address: &Felt,
        hyperlane_validator_announce_address: &Felt,
    ) -> anyhow::Result<Self> {
        let mut theoros_storage = TheorosStorage::default();

        let initial_validators = rpc_client.get_announced_validators(hyperlane_validator_announce_address).await?;
        let initial_locations = rpc_client
            .get_announced_storage_locations(hyperlane_validator_announce_address, &initial_validators)
            .await?;
        theoros_storage.validators.fill_with_initial_state(initial_validators, initial_locations).await?;

        let feed_registry_address = rpc_client.get_pragma_feed_registry_address(pragma_dispatcher_address).await?;
        let supported_feed_ids = rpc_client.get_feed_ids(&feed_registry_address).await?;
        theoros_storage.feed_ids = supported_feed_ids.into_iter().collect();

        Ok(theoros_storage)
    }

    pub fn feed_ids(&self) -> &HashSet<String> {
        &self.feed_ids
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
