use pragma_feed_types::types::FeedId;

#[starknet::interface]
pub trait IPragmaRegistry<TContractState> {
    fn add_feed_id(ref self: TContractState, feed_id: FeedId);

    fn get_all_feeds(self: @TContractState) -> Span<FeedId>;
}
