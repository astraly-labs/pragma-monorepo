pub mod event_storage;
pub mod validators_storage;

pub use event_storage::*;
pub use validators_storage::*;

use crate::types::hyperlane::DispatchEvent;

#[derive(Default)]
pub struct TheorosStorage {
    pub dispatch_events: EventStorage<DispatchEvent>,
    pub validators: ValidatorsStorage,
}

impl TheorosStorage {}
