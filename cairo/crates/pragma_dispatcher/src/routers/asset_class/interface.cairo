use core::num::traits::Zero;
use pragma_feed_types::Feed;

use pragma_feed_types::{FeedTypeId, AssetClassId};
use starknet::{contract_address_const, ContractAddress};

#[starknet::interface]
pub trait IAssetClassRouter<TContractState> {
    /// Registers a new router for the provided feed type id.
    fn register_feed_type_router(
        ref self: TContractState, feed_type_id: FeedTypeId, router_address: ContractAddress
    );
    /// Returns the asset class id of the current router.
    fn get_asset_class_id(self: @TContractState) -> AssetClassId;
    /// Returns the router address registered for the Feed Type.
    fn get_feed_type_router(self: @TContractState, feed_type_id: FeedTypeId) -> ContractAddress;
    /// For a given feed, calls the registered router [get_data] function and returns the data
    /// as bytes.
    fn get_feed_update(self: @TContractState, feed: Feed) -> alexandria_bytes::Bytes;
}

impl IAssetClassRouterZero of Zero<IAssetClassRouterDispatcher> {
    fn zero() -> IAssetClassRouterDispatcher {
        IAssetClassRouterDispatcher { contract_address: contract_address_const::<0>() }
    }

    #[inline]
    fn is_zero(self: @IAssetClassRouterDispatcher) -> bool {
        *self.contract_address == contract_address_const::<0>()
    }

    #[inline]
    fn is_non_zero(self: @IAssetClassRouterDispatcher) -> bool {
        !self.is_zero()
    }
}
