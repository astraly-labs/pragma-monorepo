pub mod syncer;

pub use syncer::*;

use serde::{Deserialize, Serialize};

use alloy::primitives::U256;

/// An Hyperlane checkpoint
#[derive(Copy, Clone, Eq, PartialEq, Debug, Serialize, Deserialize)]
pub struct Checkpoint {
    /// The merkle tree hook address
    pub merkle_tree_hook_address: U256,
    /// The mailbox / merkle tree hook domain
    pub mailbox_domain: u32,
    /// The checkpointed root
    pub root: U256,
    /// The index of the checkpoint
    pub index: u32,
}

/// A Hyperlane (checkpoint, messageId) tuple
#[derive(Copy, Clone, Eq, PartialEq, Debug, Serialize, Deserialize)]
pub struct CheckpointWithMessageId {
    /// existing Hyperlane checkpoint struct
    pub checkpoint: Checkpoint,
    /// hash of message emitted from mailbox checkpoint.index
    pub message_id: U256,
}
