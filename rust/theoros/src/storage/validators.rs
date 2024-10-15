use std::collections::HashMap;
use std::str::FromStr;

use alloy_primitives::U256;
use anyhow::bail;
use starknet::core::types::Felt;
use tokio::sync::RwLock;

use crate::types::{
    hyperlane::{CheckpointStorage, SignedCheckpointWithMessageId, ValidatorAnnouncementEvent},
    pragma::calldata::ValidatorSignature,
};

// TODO: make this code generic

/// Contains a mapping between the validators and their storages used to
/// retrieve checkpoints.
#[derive(Debug, Default)]
pub struct ValidatorStorage(RwLock<HashMap<Felt, CheckpointStorage>>);

impl ValidatorStorage {
    pub fn new() -> Self {
        Self(RwLock::new(HashMap::default()))
    }

    /// Fills the [HashMap] with the initial state fetched from the RPC.
    pub async fn fill_with_initial_state(&self, validators: Vec<Felt>, locations: Vec<Vec<String>>) -> anyhow::Result<()> {
        if validators.len() != locations.len() {
            bail!("⛔ Validators and locations vectors must have the same length");
        }

        let mut all_storages = self.0.write().await;

        for (validator, location) in validators.into_iter().zip(locations.into_iter()) {
            // TODO: in this case, we use the last storage registered for the operation
            let storage = CheckpointStorage::from_str(&location[location.len() -1])?;
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

/// Contains a mapping between the validators and their latest fetched checkpoint.
#[derive(Debug, Default)]
pub struct ValidatorCheckpointStorage(RwLock<HashMap<(Felt, U256), SignedCheckpointWithMessageId>>);

impl ValidatorCheckpointStorage {
    pub fn new() -> Self {
        Self(RwLock::new(HashMap::default()))
    }

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
    pub async fn get(&self, validator: Felt, message_id: U256) -> Option<SignedCheckpointWithMessageId> {
        self.0.read().await.get(&(validator, message_id)).cloned()
    }

    // Check the existence of a checkpoint for a given message_id
    pub async fn contains_message_id(&self, message_id: U256) -> bool {
        let all_checkpoints = self.0.read().await;

        for checkpoint in all_checkpoints.values() {
            if checkpoint.value.message_id == message_id {
                return true;
            }
        }
        false
    }

    pub async fn match_validators_with_signatures(
        &self,
        validators: &[Felt],
    ) -> anyhow::Result<Vec<ValidatorSignature>> {
        let checkpoints = self.0.read().await;

        let validator_indices: HashMap<_, _> = validators.iter().enumerate().map(|(i, v)| (*v, i as u8)).collect();

        // Convert checkpoints into signatures with correct indices
        let signers: anyhow::Result<Vec<_>> = checkpoints
            .iter()
            .map(|((validator, _), signed_checkpoint)| {
                validator_indices
                    .get(validator)
                    .map(|&index| ValidatorSignature {
                        validator_index: index,
                        signature: signed_checkpoint.signature.clone(),
                    })
                    .ok_or_else(|| anyhow::anyhow!("Validator not found: {}", validator))
            })
            .collect();

        signers
    }
}
