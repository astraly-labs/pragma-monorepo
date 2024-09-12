use pragma_feed_types::FeedId;

#[starknet::interface]
pub trait IPragmaFeedRegistry<TContractState> {
    /// Adds the [feed_id] into the Registry.
    fn add_feed(ref self: TContractState, feed_id: FeedId);
    /// Removes the [feed_id] from the Registry.
    fn remove_feed(ref self: TContractState, feed_id: FeedId);
    /// Returns all the feed ids stored in the registry.
    fn get_all_feeds(self: @TContractState) -> Array<FeedId>;
    /// Returns true if the [feed_id] provided is stored in the registry,
    /// else false.
    fn feed_exists(self: @TContractState, feed_id: FeedId) -> bool;
}
