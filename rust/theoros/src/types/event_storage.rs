use parking_lot::RwLock;
use std::collections::VecDeque;

use crate::types::dispatch_event::DispatchEvent;

/// FIFO Buffer of fixed size used to store DispatchEvent from our
/// oracle contract ; the first element being the latest.
pub struct EventStorage {
    dispatches: RwLock<VecDeque<DispatchEvent>>,
    max_size: usize,
}

impl EventStorage {
    pub fn new(max_size: usize) -> Self {
        Self { dispatches: RwLock::new(VecDeque::with_capacity(max_size)), max_size }
    }

    pub fn add(&self, dispatch: DispatchEvent) {
        let mut dispatches = self.dispatches.write();
        dispatches.push_front(dispatch);
        if dispatches.len() > self.max_size {
            dispatches.pop_back();
        }
    }

    pub fn latest(&self) -> Option<DispatchEvent> {
        self.dispatches.read().front().cloned()
    }

    pub fn all(&self) -> Vec<DispatchEvent> {
        self.dispatches.read().iter().cloned().collect()
    }
}
