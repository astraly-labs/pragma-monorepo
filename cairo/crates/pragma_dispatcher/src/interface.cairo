use pragma_feed_types::{FeedId};
use starknet::ContractAddress;

#[starknet::interface]
pub trait IPragmaDispatcher<TContractState> {
    /// Returns the registered Pragma Oracle address.
    fn get_pragma_oracle_address(self: @TContractState) -> ContractAddress;
    /// Returns the registered Pragma Feed Registry address.
    fn get_pragma_feed_registry_address(self: @TContractState) -> ContractAddress;
    /// Returns the registered Hyperlane Mailbox address.
    fn get_hyperlane_mailbox_address(self: @TContractState) -> ContractAddress;

    /// Returns the list of supported feeds.
    fn supported_feeds(self: @TContractState) -> Span<FeedId>;

    /// Dispatch updates through the Hyperlane mailbox for the specified list
    /// of [Span<FeedId>].
    fn dispatch(self: @TContractState, feed_ids: Span<FeedId>);
}
