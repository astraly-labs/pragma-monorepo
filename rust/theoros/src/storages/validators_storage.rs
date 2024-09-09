use std::collections::{HashMap, HashSet};
use std::str::FromStr;

use starknet::core::types::Felt;
use tokio::sync::RwLock;

use crate::types::hyperlane::{CheckpointFetcherConf, ValidatorAnnouncementEvent};

/// Contains a mapping between the validators and their fetchers used to
/// retrieve their checkpoints.
#[derive(Debug, Default)]
pub struct ValidatorsStorage(RwLock<HashMap<Felt, HashSet<CheckpointFetcherConf>>>);

impl ValidatorsStorage {
    pub fn new() -> Self {
        Self(RwLock::new(HashMap::default()))
    }

    pub async fn add(&self, validator: Felt, fetcher: CheckpointFetcherConf) -> anyhow::Result<()> {
        let mut all_storages = self.0.write().await;
        let validator_storages = all_storages.entry(validator).or_insert_with(HashSet::new);
        validator_storages.insert(fetcher);
        Ok(())
    }

    pub async fn add_from_announcement_event(&self, event: ValidatorAnnouncementEvent) -> anyhow::Result<()> {
        let validator: Felt = event.validator.into();
        let fetcher = CheckpointFetcherConf::from_str(&event.storage_location)?;
        self.add(validator, fetcher).await
    }

    pub async fn all(&self) -> HashMap<Felt, HashSet<CheckpointFetcherConf>> {
        self.0.read().await.clone()
    }
}
