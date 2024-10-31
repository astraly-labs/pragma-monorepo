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

    /// TODO, explain + re-assert the existence of this.
    /// Should probably be used in the context of the Hyperlane service:
    /// * each validators try to query the signatures for the cached events
    /// * store signature for each successful queries
    /// * if at least one signature is retrieved, remove from the cache
    ///   (hyperlane service query the latest events only, they should)
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
                    // TODO: Emit the websocket notification
                }
                cache_write.remove(&message_id);
                tracing::debug!("Processed cached event with message ID: {:x}", message_id);
            }
        }
        Ok(())
    }
}
