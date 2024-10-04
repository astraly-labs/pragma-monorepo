use std::collections::{HashMap};
use std::sync::Arc;
use tokio::sync::RwLock;
use alloy_primitives::U256;
use crate::types::hyperlane::DispatchEvent;
const DEFAULT_STORAGE_MAX_SIZE: usize = 16;
use anyhow::Result;

/// FIFO Buffer of fixed size used to store events.
/// The first element is the latest.
#[derive(Debug, Default)]
pub struct EventStorage {
    events: RwLock<HashMap<U256, DispatchEvent>>,
}

impl EventStorage {
    /// Creates a new `EventStorage` with the specified maximum size.
    pub fn new(max_size: usize) -> Self {
        Self {
            events: RwLock::new(HashMap::new()),
        }
    }

    pub async fn add(&self, message_id: U256, event: DispatchEvent) -> Result<()> {
        let mut events = self.events.write().await;
        events.insert(message_id, event);
        Ok(())
    }

    pub async fn get(&self, message_id: &U256) -> Result<Option<DispatchEvent>> {
        let events = self.events.read().await;
        Ok(events.get(message_id).cloned())
    }

    pub async fn get_all(&self) -> Result<Vec<(U256, DispatchEvent)>> {
        let events = self.events.read().await;
        Ok(events.iter().map(|(k, v)| (*k, v.clone())).collect())
    }

}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_event_storage() {
        let storage = EventStorage::new(3);

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
