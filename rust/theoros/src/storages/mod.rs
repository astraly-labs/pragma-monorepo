pub mod event_storage;
pub mod validators_storage;

pub use event_storage::*;
pub use validators_storage::*;

#[allow(unused)]
pub struct TheorosStorage {
    pub events: EventStorage,
    pub validators: ValidatorsStorage,
}

impl TheorosStorage {}
