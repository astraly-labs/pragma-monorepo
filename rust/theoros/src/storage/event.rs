use std::collections::HashMap;
use std::sync::Arc;

use alloy::primitives::U256;
use anyhow::Result;
use pragma_utils::conversions::alloy::hex_str_to_u256;
use tokio::sync::RwLock;

use crate::types::hyperlane::DispatchUpdate;
use crate::{storage::ValidatorsCheckpointsStorage, types::hyperlane::DispatchEvent};

#[derive(Debug, Clone)]
pub struct DispatchUpdateInfos {
    pub update: DispatchUpdate,
    pub emitter_chain_id: u32,
    pub emitter_address: String,
    pub nonce: u32,
    pub message_id: U256,
}

impl DispatchUpdateInfos {
    pub fn new(message_id: U256, event: &DispatchEvent, update: &DispatchUpdate) -> Self {
        DispatchUpdateInfos {
            update: update.clone(),
            emitter_address: event.message.header.sender.to_string(),
            emitter_chain_id: event.message.header.origin,
            nonce: event.message.header.nonce,
            message_id,
        }
    }
}

/// Contains a mapping between a feed_id and the latest dispatch update.
#[derive(Debug, Default)]
pub struct EventStorage {
    events: RwLock<HashMap<U256, DispatchUpdateInfos>>,
}

impl EventStorage {
    /// Insert the latest dispatch update for a feed_id.
    pub async fn add(&self, feed_id: String, event: DispatchUpdateInfos) -> Result<()> {
        let mut events = self.events.write().await;
        let feed_id = hex_str_to_u256(&feed_id)?;
        events.insert(feed_id, event);
        Ok(())
    }

    /// Retrieves the latest dispatch update for a feed_id;
    pub async fn get(&self, feed_id: &str) -> Result<Option<DispatchUpdateInfos>> {
        let events = self.events.read().await;
        let feed_id = hex_str_to_u256(feed_id)?;
        Ok(events.get(&feed_id).cloned())
    }

    /// Returns the current mapping as a Vec.
    pub async fn as_vec(&self) -> Result<Vec<(U256, DispatchUpdateInfos)>> {
        let events = self.events.read().await;
        Ok(events.iter().map(|(k, v)| (*k, v.clone())).collect())
    }

    /// TODO, explain + re-assert the existence of this.
    /// Retrieves multiple events by their feed IDs.
    /// Returns a tuple of (found_events, first_missing_feed_id).
    /// If all feed IDs are found, first_missing_feed_id will be None.
    pub async fn get_vec(&self, feed_ids: &[String]) -> Result<(Vec<DispatchUpdateInfos>, Option<String>)> {
        let events = self.events.read().await;
        let mut result = Vec::with_capacity(feed_ids.len());
        let mut missing_feed_id = None;

        for feed_id in feed_ids {
            let u256_feed_id = hex_str_to_u256(feed_id)?;
            match events.get(&u256_feed_id) {
                Some(event) => result.push(event.clone()),
                None => {
                    missing_feed_id = Some(feed_id.clone());
                    break;
                }
            }
        }

        Ok((result, missing_feed_id))
    }
}

/// Contains a Mapping between message ids and the corresponding Event.
#[derive(Clone, Default)]
pub struct EventCache {
    cache: Arc<RwLock<HashMap<U256, DispatchEvent>>>,
}

impl EventCache {
    /// Insert a new mapping between a message_id & an Event.
    pub async fn add(&self, message_id: U256, event: &DispatchEvent) {
        let mut cache = self.cache.write().await;
        cache.insert(message_id, event.clone());
    }

    /// Returns the number of mappings stored.
    pub async fn len(&self) -> usize {
        self.cache.read().await.len()
    }

    /// Returns the mappings as a Vec.
    /// Will contain a tuple, first element being the message_id and second the Event.
    pub async fn as_vec(&self) -> Vec<(U256, DispatchEvent)> {
        let cache = self.cache.read().await;
        cache.iter().map(|(k, v)| (*k, v.clone())).collect()
    }

    /// TODO, explain + re-assert the existence of this.
    pub async fn process_cached_events(
        &self,
        checkpoint_storage: &ValidatorsCheckpointsStorage,
        event_storage: &EventStorage,
    ) -> Result<()> {
        let mut cache_write = self.cache.write().await;

        for (message_id, dispatch_event) in cache_write.clone().into_iter() {
            if checkpoint_storage.contains_message_id(message_id).await {
                for update in dispatch_event.message.body.updates.iter() {
                    let feed_id = update.feed_id();
                    let dispatch_update_infos = DispatchUpdateInfos::new(message_id, &dispatch_event, update);
                    event_storage.add(feed_id, dispatch_update_infos).await?;
                }
                cache_write.remove(&message_id);
                tracing::debug!("Processed cached event with message ID: {:x}", message_id);
            }
        }
        Ok(())
    }
}
