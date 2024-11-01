use std::collections::{BTreeMap, HashMap};
use std::sync::Arc;

use starknet::core::types::Felt;
use tokio::sync::RwLock;

use crate::types::hyperlane::{DispatchEvent, SignedCheckpointWithMessageId};

/// Mapping between messages nonces and their corresponding Event.
#[derive(Clone, Default)]
pub struct UnsignedCheckpointsStorage {
    cache: Arc<RwLock<BTreeMap<u32, DispatchEvent>>>,
}

impl UnsignedCheckpointsStorage {
    /// Insert a new mapping between a nonce & an Event.
    pub async fn add(&self, nonce: u32, event: &DispatchEvent) {
        let mut cache = self.cache.write().await;
        cache.insert(nonce, event.clone());
    }

    /// Retrieve all nonces currently stored, in sorted order.
    pub async fn nonces(&self) -> Vec<u32> {
        let cache = self.cache.read().await;
        cache.keys().cloned().collect()
    }

    /// Remove a nonce from the storage.
    pub async fn remove(&self, nonce: u32) {
        let mut cache = self.cache.write().await;
        cache.remove(&nonce);
    }

    /// Get the event associated with a nonce.
    pub async fn get(&self, nonce: u32) -> Option<DispatchEvent> {
        let cache = self.cache.read().await;
        cache.get(&nonce).cloned()
    }
}

/// Mapping between the validators and their signed checkpoint for a given nonce.
#[derive(Debug, Default)]
pub struct SignedCheckpointsStorage(pub RwLock<HashMap<(Felt, u32), SignedCheckpointWithMessageId>>);

impl SignedCheckpointsStorage {
    /// Adds or updates the [SignedCheckpointWithMessageId] for the given validator
    pub async fn add(
        &self,
        validator: Felt,
        nonce: u32,
        checkpoint: SignedCheckpointWithMessageId,
    ) -> anyhow::Result<()> {
        let mut all_checkpoints = self.0.write().await;
        all_checkpoints.insert((validator, nonce), checkpoint);
        Ok(())
    }

    // Check if the given validator has a checkpoint for the given nonce.
    pub async fn exists(&self, validator: Felt, nonce: u32) -> bool {
        self.0.read().await.contains_key(&(validator, nonce))
    }

    // For the provided list of validators, returns all their signed checkpoints for the
    // provided message_id.
    pub async fn get(&self, validators: &[Felt], searched_nonce: u32) -> Vec<SignedCheckpointWithMessageId> {
        let lock = self.0.read().await;

        let mut checkpoints = Vec::new();
        // Iterate over the map with tuple key (validator, message_id)
        for ((validator, nonce), checkpoint) in lock.iter() {
            // Only include if validator is in the provided list and message_id matches
            if nonce == &searched_nonce && validators.contains(validator) {
                checkpoints.push(checkpoint.clone());
            }
        }

        checkpoints
    }
}