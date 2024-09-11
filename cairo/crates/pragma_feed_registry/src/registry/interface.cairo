use pragma_feed_types::types::{FeedId};

#[starknet::interface]
pub trait IPragmaRegistry<TContractState> {
    fn add_feed_id(ref self: TContractState, feed_id: FeedId);
    fn get_all_feeds(self: @TContractState) -> Array<FeedId>;
    fn feed_exists(self: @TContractState, searched_feed_id: FeedId) -> bool;
}
