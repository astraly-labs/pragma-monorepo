use crate::storage::{DispatchUpdateInfos, EventStorage};
use crate::types::hyperlane::HasFeedId;
use crate::{storage::ValidatorCheckpointStorage, types::hyperlane::DispatchEvent};
use alloy::primitives::U256;
use anyhow::Result;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
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
                tracing::info!("Processed cached event with message ID: {:?}", message_id);
            }
        }

        // Remove processed events from cache
        if !to_remove.is_empty() {
            let mut cache = self.cache.write().await;
            for message_id in &to_remove {
                cache.remove(message_id);
            }
            tracing::info!("Removed {} processed events from cache", to_remove.len());
        }

        Ok(())
    }

    pub async fn get_cache_size(&self) -> usize {
        self.cache.read().await.len()
    }
}
