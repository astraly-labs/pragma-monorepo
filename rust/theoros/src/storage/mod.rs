pub mod checkpoints;
pub mod feed_id;
pub mod updates;
pub mod validator;

pub use checkpoints::*;
pub use feed_id::*;
pub use updates::*;
pub use validator::*;

use starknet::core::types::Felt;
use tokio::sync::broadcast::Sender;

use crate::{
    rpc::starknet::{HyperlaneCalls, PragmaFeedsRegistryCalls, StarknetRpc},
    types::hyperlane::NewUpdatesAvailableEvent,
};

pub struct TheorosStorage {
    feed_ids: FeedIdsStorage,
    validators_fetchers: ValidatorsFetchersStorage,
    signed_checkpoints: SignedCheckpointsStorage,
    unsigned_checkpoints: UnsignedCheckpointsStorage,
    latest_update_per_feed: LatestUpdatePerFeedStorage,
    // websocket notifications
    feeds_updated_tx: Sender<NewUpdatesAvailableEvent>,
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

        let mut validators_fetchers = ValidatorsFetchersStorage::default();
        validators_fetchers.fill_with_initial_state(initial_validators, initial_locations).await?;

        let supported_feed_ids = rpc_client.get_feed_ids(pragma_feeds_registry_address).await?;
        let feed_ids = FeedIdsStorage::from_rpc_response(supported_feed_ids);

        Ok(Self {
            feed_ids,
            validators_fetchers,
            signed_checkpoints: SignedCheckpointsStorage::default(),
            unsigned_checkpoints: UnsignedCheckpointsStorage::default(),
            latest_update_per_feed: LatestUpdatePerFeedStorage::default(),
            feeds_updated_tx: tokio::sync::broadcast::channel(1024).0,
        })
    }

    pub fn feed_ids(&self) -> &FeedIdsStorage {
        &self.feed_ids
    }

    pub fn validators_fetchers(&self) -> &ValidatorsFetchersStorage {
        &self.validators_fetchers
    }

    pub fn signed_checkpoints(&self) -> &SignedCheckpointsStorage {
        &self.signed_checkpoints
    }

    pub fn latest_update_per_feed(&self) -> &LatestUpdatePerFeedStorage {
        &self.latest_update_per_feed
    }

    pub fn unsigned_checkpoints(&self) -> &UnsignedCheckpointsStorage {
        &self.unsigned_checkpoints
    }

    pub fn feeds_updated_tx(&self) -> &Sender<NewUpdatesAvailableEvent> {
        &self.feeds_updated_tx
    }
}
