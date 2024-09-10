use pragma_feed_types::types::{FeedId, FeedTypeId, AssetClassId, PairId};

#[starknet::interface]
pub trait IPragmaRegistry<TContractState> {
    fn add_asset_class(ref self: TContractState, asset_class_id: u16);
    fn add_feed_type(ref self: TContractState, feed_type_id: u16);

    fn add_feed_id(ref self: TContractState, feed_id: FeedId);

    fn get_asset_class_id(self: @TContractState, feed_id: FeedId) -> AssetClassId;
    fn get_feed_type_id(self: @TContractState, feed_id: FeedId) -> FeedTypeId;
    fn get_pair_id(self: @TContractState, feed_id: FeedId) -> PairId;
}
