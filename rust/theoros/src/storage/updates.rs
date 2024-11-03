use std::collections::HashMap;

use alloy::primitives::U256;
use tokio::sync::RwLock;

use crate::types::hyperlane::DispatchUpdateInfos;

/// Contains a mapping between feed ids and their latest dispatch update.
#[derive(Debug, Default)]
pub struct LatestUpdatePerFeedStorage(RwLock<HashMap<U256, DispatchUpdateInfos>>);

impl LatestUpdatePerFeedStorage {
    /// Insert the latest [`DispatchUpdateInfos`] for a feed id.
    pub async fn add(&self, feed_id: U256, event: DispatchUpdateInfos) {
        let mut lock = self.0.write().await;
        lock.insert(feed_id, event);
    }

    /// Retrieves the latest [`DispatchUpdateInfos`] for a feed id.
    pub async fn get(&self, feed_id: &U256) -> Option<DispatchUpdateInfos> {
        let lock = self.0.read().await;
        lock.get(feed_id).cloned()
    }
}
