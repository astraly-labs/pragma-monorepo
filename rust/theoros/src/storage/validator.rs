use std::str::FromStr;
use std::{collections::HashMap, sync::Arc};

use alloy::primitives::U256;
use anyhow::bail;
use starknet::core::types::Felt;
use tokio::sync::RwLock;

use crate::types::hyperlane::{
    CheckpointStorage, FetchFromStorage, SignedCheckpointWithMessageId, ValidatorAnnouncementEvent,
};

// TODO: Rename this. It should be clear that it is a Validator => StorageLocation mapping.
// TODO: The ValidatorsLocationStorage should contain the builded Location, not the CheckpointStorage.
// Currently, we are building it everytime in the Hyperlane service using: checkpoint.build()

/// Contains a mapping between the validators and their storages used to
/// retrieve checkpoints.
#[derive(Debug, Default)]
pub struct ValidatorsLocationStorage(RwLock<HashMap<Felt, Arc<Box<dyn FetchFromStorage>>>>);

impl ValidatorsLocationStorage {
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

/// Contains a mapping between the validators and their latest fetched checkpoint.
#[derive(Debug, Default)]
pub struct ValidatorsCheckpointsStorage(pub RwLock<HashMap<(Felt, U256), SignedCheckpointWithMessageId>>);

impl ValidatorsCheckpointsStorage {
    /// Adds or updates the [SignedCheckpointWithMessageId] for the given validator
    pub async fn add(
        &self,
        validator: Felt,
        message_id: U256,
        checkpoint: SignedCheckpointWithMessageId,
    ) -> anyhow::Result<()> {
        let mut all_checkpoints = self.0.write().await;
        all_checkpoints.insert((validator, message_id), checkpoint);
        Ok(())
    }

    /// Returns all the checkpoints for each validator
    pub async fn all(&self) -> HashMap<(Felt, U256), SignedCheckpointWithMessageId> {
        self.0.read().await.clone()
    }

    /// Returns the checkpoint for the given validator and message Id
    pub async fn get(&self, validator: &Felt, message_id: U256) -> Option<SignedCheckpointWithMessageId> {
        self.0.read().await.get(&(*validator, message_id)).cloned()
    }

    // Check if any of the validators has a checkpoint signed for the provided message id.
    pub async fn contains_message_id(&self, message_id: U256) -> bool {
        let all_checkpoints = self.0.read().await;

        for checkpoint in all_checkpoints.values() {
            if checkpoint.value.message_id == message_id {
                return true;
            }
        }
        false
    }

    // Check if the given validator has a checkpoint for the given message_id.
    pub async fn exists(&self, validator: Felt, message_id: U256) -> bool {
        self.0.read().await.contains_key(&(validator, message_id))
    }

    // For the provided list of validators, returns all their signed checkpoints for the
    // provided message_id.
    pub async fn get_validators_signed_checkpoints(
        &self,
        validators: &[Felt],
        searched_message_id: U256,
    ) -> anyhow::Result<Vec<SignedCheckpointWithMessageId>> {
        let checkpoints = self.0.read().await;

        let mut signatures = Vec::new();
        // Iterate over the map with tuple key (validator, message_id)
        for ((validator, message_id), checkpoint) in checkpoints.iter() {
            // Only include if validator is in the provided list and message_id matches
            if message_id == &searched_message_id && validators.contains(validator) {
                signatures.push(checkpoint.clone());
            }
        }

        Ok(signatures)
    }
}
