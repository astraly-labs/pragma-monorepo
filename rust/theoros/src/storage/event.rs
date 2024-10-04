use std::collections::{HashMap};
use std::sync::Arc;
use tokio::sync::RwLock;
use alloy_primitives::U256;
use crate::types::hyperlane::DispatchUpdate;
const DEFAULT_STORAGE_MAX_SIZE: usize = 16;
use anyhow::Result;

/// FIFO Buffer of fixed size used to store events.
/// The first element is the latest.
#[derive(Debug, Default)]
pub struct EventStorage {
    events: RwLock<HashMap<String, DispatchUpdate>>,
}

impl EventStorage {
    /// Creates a new `EventStorage` with the specified maximum size.
    pub fn new() -> Self {
        Self {
            events: RwLock::new(HashMap::new()),
        }
    }

    pub async fn add(&self, feed_id: String, event: DispatchUpdate) -> Result<()> {
        let mut events = self.events.write().await;
        events.insert(feed_id, event);
        Ok(())
    }

    pub async fn get(&self, message_id: &String) -> Result<Option<DispatchUpdate>> {
        let events = self.events.read().await;
        Ok(events.get(message_id).cloned())
    }

    pub async fn get_all(&self) -> Result<Vec<(String, DispatchUpdate)>> {
        let events = self.events.read().await;
        Ok(events.iter().map(|(k, v)| (k.clone(), v.clone())).collect())
    }

}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_event_storage() {
        let storage = EventStorage::new();

        // TODO refactor tests
        // storage.add(1, 1).await;
        // storage.add(2, 2).await;
        // storage.add(3, 3).await;
        // storage.add(4,4).await;

        // assert_eq!(storage.get(1).await.unwrap(), Ok(1));
        // assert_eq!(storage.get(2).await, Ok(2));
        // assert_eq!(storage.all().await, vec![4, 3, 2]);
    }
}
