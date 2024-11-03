use std::str::FromStr;
use std::{collections::HashMap, sync::Arc};

use anyhow::bail;
use dashmap::DashMap;
use starknet::core::types::Felt;

use crate::types::hyperlane::{CheckpointStorage, FetchFromStorage, ValidatorAnnouncementEvent};

/// Mapping between the validators and their fetcher used to
/// retrieve signed checkpoints.
#[derive(Debug, Default)]
pub struct ValidatorsFetchersStorage(Arc<DashMap<Felt, Arc<Box<dyn FetchFromStorage>>>>);

impl ValidatorsFetchersStorage {
    /// Fills the [DashMap] with the initial state fetched from the RPC.
    pub async fn fill_with_initial_state(
        &mut self,
        validators: Vec<Felt>,
        locations: Vec<Vec<String>>,
    ) -> anyhow::Result<()> {
        if validators.len() != locations.len() {
            bail!("⛔ Validators and locations vectors must have the same length");
        }

        for (validator, location) in validators.into_iter().zip(locations.into_iter()) {
            // TODO: This should be a feature. We sometime want to have a local storage.
            if location[location.len() - 1].starts_with("file") {
                continue;
            }
            let storage = CheckpointStorage::from_str(&location[location.len() - 1])?;
            let storage_fetcher = storage.build().await?;
            self.0.insert(validator, Arc::new(storage_fetcher));
        }

        Ok(())
    }

    /// Adds or updates the [CheckpointStorage] for the given validator
    pub async fn build_and_add(&self, validator: Felt, storage: CheckpointStorage) -> anyhow::Result<()> {
        let storage_fetcher = storage.build().await?;
        self.0.insert(validator, Arc::new(storage_fetcher));
        Ok(())
    }

    /// Adds or updates the [CheckpointStorage] for the given validator from a [ValidatorAnnouncementEvent]
    /// NOTE: This won't work with local storage.
    /// TODO: This should be a feature. We sometime want to have a local storage.
    pub async fn add_from_announcement_event(&self, event: ValidatorAnnouncementEvent) -> anyhow::Result<()> {
        let validator: Felt = event.validator.into();
        if event.storage_location.starts_with("file") {
            return Ok(());
        }
        let storage = CheckpointStorage::from_str(&event.storage_location)?;
        self.build_and_add(validator, storage).await?;
        Ok(())
    }

    /// Returns all registered mappings between validators & their location storage.
    pub fn all(&self) -> HashMap<Felt, Arc<Box<dyn FetchFromStorage>>> {
        self.0.iter().map(|entry| (*entry.key(), entry.value().clone())).collect()
    }
}
