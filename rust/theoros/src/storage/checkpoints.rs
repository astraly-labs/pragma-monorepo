use std::collections::{BTreeMap, HashMap};
use std::sync::Arc;

use starknet::core::types::Felt;
use tokio::sync::RwLock;

use crate::types::hyperlane::{DispatchEvent, SignedCheckpointWithMessageId};

/// Mapping between messages nonces and their corresponding Event.
#[derive(Clone, Default)]
pub struct UnsignedCheckpointsStorage(Arc<RwLock<BTreeMap<u32, DispatchEvent>>>);

impl UnsignedCheckpointsStorage {
    /// Insert a new mapping between a nonce & an Event.
    pub async fn add(&self, nonce: u32, event: &DispatchEvent) {
        let mut lock = self.0.write().await;
        lock.insert(nonce, event.clone());
    }

    /// Retrieve all nonces currently stored, in ascending order.
    pub async fn nonces(&self) -> Vec<u32> {
        let lock = self.0.read().await;
        lock.keys().cloned().collect()
    }

    /// Remove a nonce from the storage.
    pub async fn remove(&self, nonce: u32) {
        let mut lock = self.0.write().await;
        lock.remove(&nonce);
    }

    /// Get the event associated with a nonce.
    pub async fn get(&self, nonce: u32) -> Option<DispatchEvent> {
        let lock = self.0.read().await;
        lock.get(&nonce).cloned()
    }
}

/// Mapping between the validators and their signed checkpoint for a given nonce.
#[derive(Debug, Default)]
pub struct SignedCheckpointsStorage(RwLock<HashMap<(Felt, u32), SignedCheckpointWithMessageId>>);

impl SignedCheckpointsStorage {
    /// Adds or updates the [SignedCheckpointWithMessageId] for the given validator
    pub async fn add(&self, validator: Felt, nonce: u32, checkpoint: SignedCheckpointWithMessageId) {
        let mut lock = self.0.write().await;
        lock.insert((validator, nonce), checkpoint);
    }

    // For the provided list of validators, returns all their signed checkpoints for the
    // provided message_id.
    pub async fn get(&self, validators: &[Felt], searched_nonce: u32) -> Vec<(Felt, SignedCheckpointWithMessageId)> {
        let lock = self.0.read().await;

        let mut checkpoints = Vec::with_capacity(lock.len());
        // Iterate over the map with tuple key (validator, message_id)
        for ((validator, nonce), checkpoint) in lock.iter() {
            // Only include if validator is in the provided list and message_id matches
            if nonce == &searched_nonce && validators.contains(validator) {
                checkpoints.push((*validator, checkpoint.clone()));
            }
        }

        checkpoints
    }

    // Check if the given validator has a checkpoint for the given nonce.
    pub async fn validator_signed_nonce(&self, validator: Felt, nonce: u32) -> bool {
        self.0.read().await.contains_key(&(validator, nonce))
    }

    /// Checks if all validators have signed a nonce.
    pub async fn all_validators_signed_nonce(&self, validators: &[Felt], nonce: u32) -> bool {
        let lock = self.0.read().await;
        validators.iter().all(|validator| lock.contains_key(&(*validator, nonce)))
    }
}
