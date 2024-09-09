pub mod dispatch_event;
pub mod validator_announcement_event;

pub use dispatch_event::*;
pub use validator_announcement_event::*;

use apibara_core::starknet::v1alpha2::FieldElement;

pub trait FromStarknetEventData: Sized {
    fn from_starknet_event_data(data: impl Iterator<Item = FieldElement>) -> anyhow::Result<Self>;
}
