use std::collections::HashSet;
use std::sync::Arc;
use tokio::sync::RwLock;

/// Contains the registered feed ids.
#[derive(Debug, Default, Clone)]
pub struct FeedIdsStorage(Arc<RwLock<HashSet<String>>>);

impl FeedIdsStorage {
    pub fn new() -> Self {
        Self(Arc::new(RwLock::new(HashSet::new())))
    }

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

    /// Returns the number of feed IDs in the storage.
    pub async fn len(&self) -> usize {
        let feed_ids = self.0.read().await;
        feed_ids.len()
    }

    /// Returns true if the storage is empty.
    pub async fn is_empty(&self) -> bool {
        let feed_ids = self.0.read().await;
        feed_ids.is_empty()
    }

    /// Returns a clone of the inner HashSet.
    pub async fn clone_inner(&self) -> HashSet<String> {
        let feed_ids = self.0.read().await;
        feed_ids.clone()
    }

    /// Performs an operation on the inner HashSet while holding the write lock.
    pub async fn with_inner<F, R>(&self, f: F) -> R
    where
        F: FnOnce(&mut HashSet<String>) -> R,
    {
        let mut feed_ids = self.0.write().await;
        f(&mut feed_ids)
    }

    /// Returns an iterator over the feed IDs.
    pub async fn iter(&self) -> impl Iterator<Item = String> {
        let feed_ids = self.0.read().await;
        feed_ids.iter().cloned().collect::<Vec<_>>().into_iter()
    }
}
