use parking_lot::RwLock;
use std::collections::VecDeque;

use crate::types::dispatch_event::DispatchEvent;
use crate::types::network::Network;

pub struct EventStorage {
    mainnet: DispatchEvents,
    sepolia: DispatchEvents,
}

impl EventStorage {
    pub fn new(max_size: usize) -> Self {
        Self { mainnet: DispatchEvents::new(max_size), sepolia: DispatchEvents::new(max_size) }
    }

    pub fn add(&self, network: Network, dispatch: DispatchEvent) {
        match network {
            Network::Mainnet => self.mainnet.add(dispatch),
            Network::Sepolia => self.sepolia.add(dispatch),
        }
    }

    pub fn latest(&self, network: Network) -> Option<DispatchEvent> {
        match network {
            Network::Mainnet => self.mainnet.latest(),
            Network::Sepolia => self.sepolia.latest(),
        }
    }

    pub fn all(&self, network: Network) -> Vec<DispatchEvent> {
        match network {
            Network::Mainnet => self.mainnet.all(),
            Network::Sepolia => self.sepolia.all(),
        }
    }
}

pub struct DispatchEvents {
    dispatches: RwLock<VecDeque<DispatchEvent>>,
    max_size: usize,
}

impl DispatchEvents {
    fn new(max_size: usize) -> Self {
        Self { dispatches: RwLock::new(VecDeque::with_capacity(max_size)), max_size }
    }

    fn add(&self, dispatch: DispatchEvent) {
        let mut dispatches = self.dispatches.write();
        dispatches.push_front(dispatch);
        if dispatches.len() > self.max_size {
            dispatches.pop_back();
        }
    }

    fn latest(&self) -> Option<DispatchEvent> {
        self.dispatches.read().front().cloned()
    }

    fn all(&self) -> Vec<DispatchEvent> {
        self.dispatches.read().iter().cloned().collect()
    }
}
