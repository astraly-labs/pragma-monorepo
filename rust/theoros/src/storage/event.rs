use crate::types::hyperlane::DispatchUpdate;
use anyhow::Result;
use std::collections::HashMap;
use tokio::sync::RwLock;

#[derive(Debug, Clone)]
pub struct DispatchUpdateInfos {
    pub update: DispatchUpdate,
    pub emitter_chain_id: u32,
    pub emitter_address: String,
    pub nonce: u32,
}
#[derive(Debug, Default)]
pub struct EventStorage {
    events: RwLock<HashMap<String, DispatchUpdateInfos>>,
}

impl EventStorage {
    /// Creates a new `EventStorage` with the specified maximum size.
    pub fn new() -> Self {
        Self { events: RwLock::new(HashMap::new()) }
    }

    pub async fn add(&self, feed_id: String, event: DispatchUpdateInfos) -> Result<()> {
        let mut events = self.events.write().await;
        events.insert(feed_id, event);
        Ok(())
    }

    pub async fn get(&self, feed_id: &String) -> Result<Option<DispatchUpdateInfos>> {
        let events = self.events.read().await;
        Ok(events.get(feed_id).cloned())
    }

    pub async fn get_all(&self) -> Result<Vec<(String, DispatchUpdateInfos)>> {
        let events = self.events.read().await;
        Ok(events.iter().map(|(k, v)| (k.clone(), v.clone())).collect())
    }
}
