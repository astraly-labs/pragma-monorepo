pub mod event;
pub mod validators;

pub use event::*;
pub use validators::*;

use std::collections::HashSet;

use starknet::core::types::Felt;

use crate::{
    rpc::{HyperlaneCalls, PragmaWrapperCalls, StarknetRpc},
    types::hyperlane::DispatchEvent,
};

/// Theoros storage that contains:
///   * a set of all available data feeds,
///   * an events storage containing the most recents [DispatchEvent] events indexed,
///   * a mapping of all the validators and their fetchers.
#[derive(Default)]
pub struct TheorosStorage {
    data_feeds: HashSet<String>,
    validators: ValidatorStorage,
    dispatch_events: EventStorage<DispatchEvent>,
}

impl TheorosStorage {
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

    pub fn dispatch_events(&self) -> &EventStorage<DispatchEvent> {
        &self.dispatch_events
    }
}
