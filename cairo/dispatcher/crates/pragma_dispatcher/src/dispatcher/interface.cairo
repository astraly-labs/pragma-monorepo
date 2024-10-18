use alexandria_bytes::Bytes;
use pragma_dispatcher::types::hyperlane::HyperlaneMessageId;
use pragma_feed_types::{FeedWithId, FeedId, AssetClassId};
use starknet::ContractAddress;

#[starknet::interface]
pub trait IPragmaDispatcher<TContractState> {
    /// Sets the Pragma Feed Registry address.
    fn set_pragma_feed_registry_address(
        ref self: TContractState, pragma_feed_registry_address: ContractAddress
    );
    /// Sets the Hyperlane Mailbox address.
    fn set_hyperlane_mailbox_address(
        ref self: TContractState, hyperlane_mailbox_address: ContractAddress
    );
    /// Returns the registered Pragma Feed Registry address.
    fn get_pragma_feed_registry_address(self: @TContractState) -> ContractAddress;
    /// Returns the registered Hyperlane Mailbox address.
    fn get_hyperlane_mailbox_address(self: @TContractState) -> ContractAddress;

    /// Returns the complete information about a feed.
    fn get_feed(self: @TContractState, feed_id: FeedId) -> FeedWithId;
    /// Returns the list of supported feeds.
    fn supported_feeds(self: @TContractState) -> Array<FeedId>;

    /// Returns the router address registered for an Asset Class.
    fn get_asset_class_router(
        self: @TContractState, asset_class_id: AssetClassId
    ) -> ContractAddress;
    /// Register a new router for an Asset Class.
    fn register_asset_class_router(
        ref self: TContractState, asset_class_id: AssetClassId, router_address: ContractAddress
    );

    /// Dispatch updates through the Hyperlane mailbox for the specifieds
    /// [Span<FeedId>] and return the ID of the message dispatched.
    fn dispatch(ref self: TContractState, feed_ids: Span<FeedId>) -> HyperlaneMessageId;
}

#[starknet::interface]
pub trait IPragmaFeedsRegistryWrapper<TContractState> {
    /// Calls feed_exists from the Pragma Feeds Registry contract.
    fn call_feed_exists(self: @TContractState, feed_id: FeedId) -> bool;

    /// Calls get_feed from the Pragma Feeds Registry contract.
    fn call_get_feed(self: @TContractState, feed_id: FeedId) -> FeedWithId;

    /// Calls get_all_feeds from the Pragma Feeds Registry contract.
    fn call_get_all_feeds(self: @TContractState) -> Array<FeedId>;
}

#[starknet::interface]
pub trait IHyperlaneMailboxWrapper<TContractState> {
    /// Calls dispatch from the Hyperlane Mailbox contract.
    fn call_dispatch(ref self: TContractState, message_body: Bytes) -> HyperlaneMessageId;
}
