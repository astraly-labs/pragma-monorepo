use std::collections::VecDeque;

use tokio::sync::RwLock;

use crate::types::hyperlane::DispatchEvent;

/// FIFO Buffer of fixed size used to store DispatchEvent from our
/// oracle contract ; the first element being the latest.
#[derive(Debug, Default)]
pub struct EventStorage {
    dispatches: RwLock<VecDeque<DispatchEvent>>,
    max_size: usize,
}

impl EventStorage {
    pub fn new(max_size: usize) -> Self {
        Self { dispatches: RwLock::new(VecDeque::with_capacity(max_size)), max_size }
    }

    pub async fn add(&self, dispatch: DispatchEvent) {
        let mut dispatches = self.dispatches.write().await;
        dispatches.push_front(dispatch);
        if dispatches.len() > self.max_size {
            dispatches.pop_back();
        }
    }

    pub async fn latest(&self) -> Option<DispatchEvent> {
        self.dispatches.read().await.front().cloned()
    }

    pub async fn all(&self) -> Vec<DispatchEvent> {
        self.dispatches.read().await.iter().cloned().collect()
    }
}
