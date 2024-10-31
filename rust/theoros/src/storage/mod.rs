pub mod event;
pub mod feed_id;
pub mod validator;

pub use event::*;
pub use feed_id::*;
use tokio::sync::broadcast::Sender;
pub use validator::*;

use starknet::core::types::Felt;

use crate::{
    rpc::starknet::{HyperlaneCalls, PragmaFeedsRegistryCalls, StarknetRpc},
    types::hyperlane::CheckpointMatchEvent,
};

/// Theoros storage that contains:
///   * a set of all available feed ids,
///   * a mapping of all the validators and their fetchers,
///   * a mapping of all the validators and their latest fetched checkpoints for a given message_id,
///   * an event cache, used to store events that have not been signed yet,
///   * an events storage containing the most recent [`DispatchUpdateInfos`] per feed_id,
///   * (websocket) a channel to dispatch updates to the clients.
pub struct TheorosStorage {
    feed_ids: FeedIdsStorage,
    validators: ValidatorsLocationStorage,
    checkpoints: ValidatorsCheckpointsStorage,
    cached_events: EventCache,
    dispatch_events: EventStorage,
    pub feeds_channel: Sender<CheckpointMatchEvent>,
}

impl TheorosStorage {
    pub async fn from_rpc_state(
        rpc_client: &StarknetRpc,
        pragma_feeds_registry_address: &Felt,
        hyperlane_validator_announce_address: &Felt,
    ) -> anyhow::Result<Self> {
        let initial_validators = rpc_client.get_announced_validators(hyperlane_validator_announce_address).await?;
        let initial_locations = rpc_client
            .get_announced_storage_locations(hyperlane_validator_announce_address, &initial_validators)
            .await?;

        let mut validators = ValidatorsLocationStorage::default();
        validators.fill_with_initial_state(initial_validators, initial_locations).await?;

        let supported_feed_ids = rpc_client.get_feed_ids(pragma_feeds_registry_address).await?;
        let feed_ids = FeedIdsStorage::from_rpc_response(supported_feed_ids);

        let (update_tx, _) = tokio::sync::broadcast::channel(1000);

        Ok(Self {
            feed_ids,
            validators,
            checkpoints: ValidatorsCheckpointsStorage::default(),
            cached_events: EventCache::default(),
            dispatch_events: EventStorage::default(),
            feeds_channel: update_tx,
        })
    }

    pub fn feed_ids(&self) -> &FeedIdsStorage {
        &self.feed_ids
    }

    pub fn validators_locations(&self) -> &ValidatorsLocationStorage {
        &self.validators
    }

    pub fn validators_checkpoints(&self) -> &ValidatorsCheckpointsStorage {
        &self.checkpoints
    }

    pub fn dispatch_events(&self) -> &EventStorage {
        &self.dispatch_events
    }

    pub fn cached_events(&self) -> &EventCache {
        &self.cached_events
    }
}
