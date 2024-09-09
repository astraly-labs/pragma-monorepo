use std::collections::{HashMap, HashSet};
use std::str::FromStr;

use starknet::core::types::Felt;
use tokio::sync::RwLock;

use crate::types::hyperlane::{CheckpointFetcherConf, ValidatorAnnouncementEvent};

/// Contains a mapping between the validators and their fetchers used to
/// retrieve checkpoints.
#[derive(Debug, Default)]
pub struct ValidatorsStorage(RwLock<HashMap<Felt, HashSet<CheckpointFetcherConf>>>);

impl ValidatorsStorage {
    pub fn new() -> Self {
        Self(RwLock::new(HashMap::default()))
    }

    /// Adds a new [CheckpointFetcherConf] for the given validator
    pub async fn add(&self, validator: Felt, fetcher: CheckpointFetcherConf) -> anyhow::Result<()> {
        let mut all_fetchers = self.0.write().await;
        let validator_fetchers = all_fetchers.entry(validator).or_insert_with(HashSet::new);
        validator_fetchers.insert(fetcher);
        Ok(())
    }

    /// Adds a new [CheckpointFetcherConf] for the given validator from a [ValidatorAnnouncementEvent]
    pub async fn add_from_announcement_event(&self, event: ValidatorAnnouncementEvent) -> anyhow::Result<()> {
        let validator: Felt = event.validator.into();
        let fetcher = CheckpointFetcherConf::from_str(&event.storage_location)?;
        self.add(validator, fetcher).await
    }

    /// Returns all the fetchers for each validators
    pub async fn all(&self) -> HashMap<Felt, HashSet<CheckpointFetcherConf>> {
        self.0.read().await.clone()
    }
}
