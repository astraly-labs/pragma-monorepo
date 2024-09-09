pub mod event_storage;
pub mod validators_storage;

pub use event_storage::*;
pub use validators_storage::*;

use crate::types::hyperlane::DispatchEvent;

/// Theoros storage that contains:
///   * an events storage containing the most recents [DispatchEvent] events indexed,
///   * a mapping of all the validators and their fetchers.
#[derive(Default)]
pub struct TheorosStorage {
    pub dispatch_events: EventStorage<DispatchEvent>,
    pub validators: ValidatorsStorage,
}
