use std::collections::HashSet;
use std::sync::{Arc, Mutex};

/// Contains the registered feed ids.
#[derive(Debug, Default, Clone)]
pub struct FeedIdsStorage(Arc<Mutex<HashSet<String>>>);

impl FeedIdsStorage {
    pub fn new() -> Self {
        Self(Arc::new(Mutex::new(HashSet::new())))
    }

    pub fn from_rpc_response(feed_ids: Vec<String>) -> Self {
        Self(Arc::new(Mutex::new(feed_ids.into_iter().collect())))
    }

    pub fn add(&self, feed_id: String) {
        self.0.lock().unwrap().insert(feed_id);
    }

    pub fn remove(&self, feed_id: &str) {
        self.0.lock().unwrap().remove(feed_id);
    }

    /// Checks if the storage contains the given feed ID.
    pub fn contains(&self, feed_id: &str) -> bool {
        self.0.lock().unwrap().contains(feed_id)
    }

    /// Returns the number of feed IDs in the storage.
    pub fn len(&self) -> usize {
        self.0.lock().unwrap().len()
    }

    /// Returns true if the storage is empty.
    pub fn is_empty(&self) -> bool {
        self.0.lock().unwrap().is_empty()
    }

    /// Returns a clone of the inner HashSet.
    pub fn clone_inner(&self) -> HashSet<String> {
        self.0.lock().unwrap().clone()
    }

    /// Performs an operation on the inner HashSet while holding the lock.
    pub fn with_inner<F, R>(&self, f: F) -> R
    where
        F: FnOnce(&mut HashSet<String>) -> R,
    {
        let mut guard = self.0.lock().unwrap();
        f(&mut guard)
    }
}
