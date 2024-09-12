use pragma_feed_types::{FeedId};
use starknet::ContractAddress;

#[starknet::interface]
pub trait IPragmaDispatcher<TContractState> {
    fn get_pragma_oracle_address(self: @TContractState) -> ContractAddress;
    fn get_pragma_feed_registry_address(self: @TContractState) -> ContractAddress;
    fn get_hyperlane_mailbox_address(self: @TContractState) -> ContractAddress;

    fn supported_data_feeds(self: @TContractState) -> Span<FeedId>;

    fn dispatch(self: @TContractState, feed_ids: Span<FeedId>);
}
