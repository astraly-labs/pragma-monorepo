use std::collections::HashMap;
use std::sync::Arc;

use alloy::primitives::U256;
use anyhow::Result;
use tokio::sync::RwLock;

use crate::types::hyperlane::DispatchUpdate;
use crate::types::hyperlane::HasFeedId;
use crate::{storage::ValidatorCheckpointStorage, types::hyperlane::DispatchEvent};

#[derive(Debug, Clone)]
pub struct DispatchUpdateInfos {
    pub update: DispatchUpdate,
    pub emitter_chain_id: u32,
    pub emitter_address: String,
    pub nonce: u32,
}

// Event Storage

#[derive(Debug, Default)]
pub struct EventStorage {
    events: RwLock<HashMap<String, DispatchUpdateInfos>>,
}

impl EventStorage {
    /// Creates a new `EventStorage` with the specified maximum size.
    pub fn new() -> Self {
        Self { events: RwLock::new(HashMap::new()) }
    }

    pub async fn add(&self, feed_id: String, event: DispatchUpdateInfos) -> Result<()> {
        let mut events = self.events.write().await;
        events.insert(feed_id, event);
        Ok(())
    }

    pub async fn get(&self, feed_id: &String) -> Result<Option<DispatchUpdateInfos>> {
        let events = self.events.read().await;
        Ok(events.get(feed_id).cloned())
    }

    pub async fn get_all(&self) -> Result<Vec<(String, DispatchUpdateInfos)>> {
        let events = self.events.read().await;
        Ok(events.iter().map(|(k, v)| (k.clone(), v.clone())).collect())
    }
}

// Event cache

#[derive(Clone, Default)]
pub struct EventCache {
    cache: Arc<RwLock<HashMap<U256, DispatchEvent>>>,
}

impl EventCache {
    pub fn new() -> Self {
        Self { cache: Arc::new(RwLock::new(HashMap::new())) }
    }

    pub async fn add_event(&self, message_id: U256, event: &DispatchEvent) {
        let mut cache = self.cache.write().await;
        cache.insert(message_id, event.clone());
    }

    pub async fn process_cached_events(
        &self,
        checkpoint_storage: &ValidatorCheckpointStorage,
        event_storage: &EventStorage,
    ) -> Result<()> {
        let cache = self.cache.read().await;
        let mut to_remove = Vec::new();

        for (message_id, dispatch_event) in cache.iter() {
            if checkpoint_storage.contains_message_id(*message_id).await {
                // Store all updates in event
                for update in dispatch_event.message.body.updates.iter() {
                    let feed_id = update.feed_id();
                    let dispatch_update_infos = DispatchUpdateInfos {
                        update: update.clone(),
                        emitter_address: dispatch_event.message.header.sender.to_string(),
                        emitter_chain_id: dispatch_event.message.header.origin,
                        nonce: dispatch_event.message.header.nonce,
                    };
                    event_storage.add(feed_id, dispatch_update_infos).await?;
                }
                to_remove.push(*message_id);
                tracing::debug!("Processed cached event with message ID: {:?}", message_id);
            }
        }

        // Remove processed events from cache
        if !to_remove.is_empty() {
            let mut cache = self.cache.write().await;
            for message_id in &to_remove {
                cache.remove(message_id);
            }
            tracing::debug!("Removed {} processed events from cache", to_remove.len());
        }

        Ok(())
    }

    pub async fn get_cache_size(&self) -> usize {
        self.cache.read().await.len()
    }
}
