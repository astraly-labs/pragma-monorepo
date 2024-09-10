use std::collections::HashMap;
use std::str::FromStr;

use anyhow::bail;
use starknet::core::types::Felt;
use tokio::sync::RwLock;

use crate::types::hyperlane::{CheckpointStorage, ValidatorAnnouncementEvent};

/// Contains a mapping between the validators and their storages used to
/// retrieve checkpoints.
#[derive(Debug, Default)]
pub struct ValidatorStorage(RwLock<HashMap<Felt, CheckpointStorage>>);

impl ValidatorStorage {
    pub fn new() -> Self {
        Self(RwLock::new(HashMap::default()))
    }

    /// Fills the [HashMap] with the initial state fetched from the RPC.
    pub async fn fill_with_initial_state(&self, validators: Vec<Felt>, locations: Vec<String>) -> anyhow::Result<()> {
        if validators.len() != locations.len() {
            bail!("⛔ Validators and locations vectors must have the same length");
        }

        let mut all_storages = self.0.write().await;

        for (validator, location) in validators.into_iter().zip(locations.into_iter()) {
            let storage = CheckpointStorage::from_str(&location)?;
            all_storages.insert(validator, storage);
        }

        Ok(())
    }

    /// Adds or updates the [CheckpointStorage] for the given validator
    pub async fn add(&self, validator: Felt, storage: CheckpointStorage) -> anyhow::Result<()> {
        let mut all_storages = self.0.write().await;
        all_storages.insert(validator, storage);
        Ok(())
    }

    /// Adds or updates the [CheckpointStorage] for the given validator from a [ValidatorAnnouncementEvent]
    pub async fn add_from_announcement_event(&self, event: ValidatorAnnouncementEvent) -> anyhow::Result<()> {
        let validator: Felt = event.validator.into();
        let storage = CheckpointStorage::from_str(&event.storage_location)?;
        self.add(validator, storage).await
    }

    /// Returns all the storages for each validator
    pub async fn all(&self) -> HashMap<Felt, CheckpointStorage> {
        self.0.read().await.clone()
    }
}
