use std::sync::Arc;

use alloy::primitives::U256;
use dashmap::DashMap;

use crate::types::hyperlane::DispatchUpdateInfos;

/// Contains a mapping between feed ids and their latest dispatch update.
#[derive(Debug, Default)]
pub struct LatestUpdatePerFeedStorage(Arc<DashMap<U256, DispatchUpdateInfos>>);

impl LatestUpdatePerFeedStorage {
    /// Insert the latest [`DispatchUpdateInfos`] for a feed id.
    pub fn add(&self, feed_id: U256, event: DispatchUpdateInfos) {
        self.0.insert(feed_id, event);
    }

    /// Retrieves the latest [`DispatchUpdateInfos`] for a feed id.
    pub fn get(&self, feed_id: &U256) -> Option<DispatchUpdateInfos> {
        self.0.get(feed_id).map(|r| r.value().clone())
    }
}
