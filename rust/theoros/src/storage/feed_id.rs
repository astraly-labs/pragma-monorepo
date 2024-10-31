use std::collections::HashSet;
use std::sync::Arc;
use tokio::sync::RwLock;

/// Contains the registered feed ids.
#[derive(Debug, Default, Clone)]
pub struct FeedIdsStorage(Arc<RwLock<HashSet<String>>>);

impl FeedIdsStorage {
    pub fn from_rpc_response(feed_ids: Vec<String>) -> Self {
        Self(Arc::new(RwLock::new(feed_ids.into_iter().collect())))
    }

    pub async fn add(&self, feed_id: String) {
        let mut feed_ids = self.0.write().await;
        feed_ids.insert(feed_id);
    }

    pub async fn remove(&self, feed_id: &str) {
        let mut feed_ids = self.0.write().await;
        feed_ids.remove(feed_id);
    }

    /// Checks if the storage contains the given feed ID.
    pub async fn contains(&self, feed_id: &str) -> bool {
        let feed_ids = self.0.read().await;
        feed_ids.contains(feed_id)
    }

    /// Checks if all feed IDs in the given vector are present in the storage.
    /// Returns None if all IDs are present, or Some(id) with the first missing ID.
    pub async fn contains_vec(&self, feed_ids: &[String]) -> Option<String> {
        let stored_feed_ids = self.0.read().await;
        feed_ids.iter().find(|id| !stored_feed_ids.contains(*id)).cloned()
    }

    /// Returns the number of feed IDs in the storage.
    pub async fn len(&self) -> usize {
        let feed_ids = self.0.read().await;
        feed_ids.len()
    }

    /// Returns an iterator over the feed IDs.
    pub async fn iter(&self) -> impl Iterator<Item = String> {
        let feed_ids = self.0.read().await;
        feed_ids.iter().cloned().collect::<Vec<_>>().into_iter()
    }
}
