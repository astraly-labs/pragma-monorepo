use std::collections::HashMap;

use alloy::primitives::U256;
use anyhow::Result;
use tokio::sync::RwLock;

use crate::types::hyperlane::DispatchUpdateInfos;

/// Contains a mapping between feed ids and their latest dispatch update.
#[derive(Debug, Default)]
pub struct LatestUpdatePerFeedStorage {
    events: RwLock<HashMap<U256, DispatchUpdateInfos>>,
}

impl LatestUpdatePerFeedStorage {
    /// Insert the latest [`DispatchUpdateInfos`] for a feed id.
    pub async fn add(&self, feed_id: U256, event: DispatchUpdateInfos) -> Result<()> {
        let mut events = self.events.write().await;
        events.insert(feed_id, event);
        Ok(())
    }

    /// Retrieves the latest [`DispatchUpdateInfos`] for a feed id.
    pub async fn get(&self, feed_id: &U256) -> Result<Option<DispatchUpdateInfos>> {
        let events = self.events.read().await;
        Ok(events.get(feed_id).cloned())
    }
}
