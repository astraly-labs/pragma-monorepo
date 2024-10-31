use std::str::FromStr;
use std::{collections::HashMap, sync::Arc};

use anyhow::bail;
use starknet::core::types::Felt;
use tokio::sync::RwLock;

use crate::types::hyperlane::{CheckpointStorage, FetchFromStorage, ValidatorAnnouncementEvent};

/// Mapping between the validators and their fetcher used to
/// retrieve signed checkpoints.
#[derive(Debug, Default)]
pub struct ValidatorsFetchersStorage(RwLock<HashMap<Felt, Arc<Box<dyn FetchFromStorage>>>>);

impl ValidatorsFetchersStorage {
    /// Fills the [HashMap] with the initial state fetched from the RPC.
    pub async fn fill_with_initial_state(
        &mut self,
        validators: Vec<Felt>,
        locations: Vec<Vec<String>>,
    ) -> anyhow::Result<()> {
        if validators.len() != locations.len() {
            bail!("⛔ Validators and locations vectors must have the same length");
        }

        let mut all_storages = self.0.write().await;
        for (validator, location) in validators.into_iter().zip(locations.into_iter()) {
            // TODO: This should be a feature. We sometime want to have a local storage.
            if location[location.len() - 1].starts_with("file") {
                continue;
            }
            let storage = CheckpointStorage::from_str(&location[location.len() - 1])?;
            let storage_fetcher = storage.build().await?;
            all_storages.insert(validator, Arc::new(storage_fetcher));
        }

        Ok(())
    }

    /// Adds or updates the [CheckpointStorage] for the given validator
    pub async fn add(&self, validator: Felt, storage: CheckpointStorage) -> anyhow::Result<()> {
        let storage_fetcher = storage.build().await?;
        let mut all_storages = self.0.write().await;
        all_storages.insert(validator, Arc::new(storage_fetcher));
        Ok(())
    }

    /// Adds or updates the [CheckpointStorage] for the given validator from a [ValidatorAnnouncementEvent]
    pub async fn add_from_announcement_event(&self, event: ValidatorAnnouncementEvent) -> anyhow::Result<()> {
        let validator: Felt = event.validator.into();
        // TODO: This should be a feature. We sometime want to have a local storage.
        if event.storage_location.starts_with("file") {
            return Ok(());
        }
        let storage = CheckpointStorage::from_str(&event.storage_location)?;
        self.add(validator, storage).await?;
        Ok(())
    }

    /// Returns all registered mappings between validators & their location storage.
    pub async fn all(&self) -> HashMap<Felt, Arc<Box<dyn FetchFromStorage>>> {
        self.0.read().await.clone()
    }
}
