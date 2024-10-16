pub mod dispatch_event;
pub mod validator_announcement_event;

pub use dispatch_event::*;
pub use validator_announcement_event::*;

use starknet::core::types::Felt;

// TODO: Use VecDequeue for optimized pop_first (instead of Vec<Felt>)
// https://doc.rust-lang.org/std/collections/struct.VecDeque.html
pub trait FromStarknetEventData: Sized {
    fn from_starknet_event_data(data: Vec<Felt>) -> anyhow::Result<Self>;
}
