use alexandria_bytes::Bytes;
use pragma_dispatcher::types::pragma_oracle::PragmaPricesResponse;
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

#[starknet::interface]
pub trait IHyperlaneMailboxWrapper<TContractState> {
    fn _dispatch_caller(self: @TContractState, message_body: Bytes);
}

#[starknet::interface]
pub trait IPragmaOracleWrapper<TContractState> {
    fn _get_data_caller(self: @TContractState) -> PragmaPricesResponse;
}
