use dashmap::DashSet;
use std::sync::Arc;

/// Contains the registered feed ids.
#[derive(Debug, Default, Clone)]
pub struct FeedIdsStorage(Arc<DashSet<String>>);

impl FeedIdsStorage {
    pub fn from_rpc_response(feed_ids: Vec<String>) -> Self {
        let set = DashSet::new();
        for id in feed_ids {
            set.insert(id);
        }
        Self(Arc::new(set))
    }

    pub fn add(&self, feed_id: String) {
        self.0.insert(feed_id);
    }

    pub fn remove(&self, feed_id: &str) {
        self.0.remove(feed_id);
    }

    /// Checks if all feed IDs in the given vector are present in the storage.
    /// Returns None if all IDs are present, or Some(id) with the first missing ID.
    pub fn contains_vec(&self, feed_ids: &[String]) -> Option<String> {
        feed_ids.iter().find(|id| !self.0.contains(*id)).cloned()
    }

    /// Returns the number of feed IDs in the storage.
    pub fn len(&self) -> usize {
        self.0.len()
    }

    /// Returns an iterator over the feed IDs.
    pub fn iter(&self) -> impl Iterator<Item = String> {
        self.0.iter().map(|ref_multi| ref_multi.key().clone()).collect::<Vec<_>>().into_iter()
    }
}
