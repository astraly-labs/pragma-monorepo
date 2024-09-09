use std::collections::VecDeque;
use std::sync::Arc;
use tokio::sync::RwLock;

const DEFAULT_STORAGE_MAX_SIZE: usize = 16;

/// FIFO Buffer of fixed size used to store events.
/// The first element is the latest.
#[derive(Debug)]
pub struct EventStorage<T> {
    events: Arc<RwLock<VecDeque<T>>>,
    max_size: usize,
}

impl<T: Clone> EventStorage<T> {
    /// Creates a new `EventStorage` with the specified maximum size.
    pub fn new(max_size: usize) -> Self {
        Self { events: Arc::new(RwLock::new(VecDeque::with_capacity(max_size))), max_size }
    }

    /// Adds a new event to the front of the queue, removing the oldest if necessary.
    pub async fn add(&self, event: T) {
        let mut events = self.events.write().await;
        events.push_front(event);
        if events.len() > self.max_size {
            events.pop_back();
        }
    }

    /// Returns the latest event, if any.
    pub async fn latest(&self) -> Option<T> {
        self.events.read().await.front().cloned()
    }

    /// Returns all events as a vector.
    pub async fn all(&self) -> Vec<T> {
        self.events.read().await.iter().cloned().collect()
    }
}

impl<T: Clone> Default for EventStorage<T> {
    fn default() -> Self {
        Self::new(DEFAULT_STORAGE_MAX_SIZE)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_event_storage() {
        let storage = EventStorage::new(3);

        storage.add(1).await;
        storage.add(2).await;
        storage.add(3).await;
        storage.add(4).await;

        assert_eq!(storage.latest().await, Some(4));
        assert_eq!(storage.all().await, vec![4, 3, 2]);
    }
}
