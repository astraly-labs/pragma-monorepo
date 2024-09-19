use core::num::traits::Zero;
use pragma_feed_types::{Feed, FeedTypeId};
use starknet::contract_address_const;

#[starknet::interface]
pub trait IFeedTypeRouter<TContractState> {
    /// Returns the feed type id of the current router.
    fn get_feed_type_id(self: @TContractState) -> FeedTypeId;
    /// Returns the update for the feed as bytes.
    fn get_data(self: @TContractState, feed: Feed) -> alexandria_bytes::Bytes;
}

impl IFeedTypeRouterZero of Zero<IFeedTypeRouterDispatcher> {
    fn zero() -> IFeedTypeRouterDispatcher {
        IFeedTypeRouterDispatcher { contract_address: contract_address_const::<0>() }
    }

    #[inline]
    fn is_zero(self: @IFeedTypeRouterDispatcher) -> bool {
        *self.contract_address == contract_address_const::<0>()
    }

    #[inline]
    fn is_non_zero(self: @IFeedTypeRouterDispatcher) -> bool {
        !self.is_zero()
    }
}
