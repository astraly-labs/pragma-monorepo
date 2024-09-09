use std::collections::HashMap;
use std::str::FromStr;

use anyhow::bail;
use starknet::core::types::Felt;
use tokio::sync::RwLock;

use crate::types::hyperlane::{CheckpointFetcherConf, ValidatorAnnouncementEvent};

/// Contains a mapping between the validators and their fetchers used to
/// retrieve checkpoints.
#[derive(Debug, Default)]
pub struct ValidatorsStorage(RwLock<HashMap<Felt, CheckpointFetcherConf>>);

impl ValidatorsStorage {
    pub fn new() -> Self {
        Self(RwLock::new(HashMap::default()))
    }

    pub async fn fill_with_initial_state(&self, validators: Vec<Felt>, locations: Vec<String>) -> anyhow::Result<()> {
        if validators.len() != locations.len() {
            bail!("Validators and locations vectors must have the same length");
        }

        let mut all_fetchers = self.0.write().await;

        for (validator, location) in validators.into_iter().zip(locations.into_iter()) {
            let fetcher = CheckpointFetcherConf::from_str(&location)?;
            all_fetchers.insert(validator, fetcher);
        }

        Ok(())
    }

    /// Adds or updates the [CheckpointFetcherConf] for the given validator
    pub async fn add(&self, validator: Felt, fetcher: CheckpointFetcherConf) -> anyhow::Result<()> {
        let mut all_fetchers = self.0.write().await;
        all_fetchers.insert(validator, fetcher);
        Ok(())
    }

    /// Adds or updates the [CheckpointFetcherConf] for the given validator from a [ValidatorAnnouncementEvent]
    pub async fn add_from_announcement_event(&self, event: ValidatorAnnouncementEvent) -> anyhow::Result<()> {
        let validator: Felt = event.validator.into();
        let fetcher = CheckpointFetcherConf::from_str(&event.storage_location)?;
        self.add(validator, fetcher).await
    }

    /// Returns all the fetchers for each validator
    pub async fn all(&self) -> HashMap<Felt, CheckpointFetcherConf> {
        self.0.read().await.clone()
    }
}
