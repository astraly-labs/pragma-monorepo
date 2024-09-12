use alexandria_bytes::Bytes;
use pragma_dispatcher::types::hyperlane::HyperlaneMessageId;
use pragma_dispatcher::types::pragma_oracle::{SummaryStatsComputation};
use pragma_feed_types::{FeedId};
use pragma_lib::types::{PragmaPricesResponse, DataType, AggregationMode};
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

    /// Dispatch updates through the Hyperlane mailbox for the specifieds
    /// [Span<FeedId>] and return the ID of the message dispatched.
    fn dispatch(self: @TContractState, feed_ids: Span<FeedId>) -> HyperlaneMessageId;
}

#[starknet::interface]
pub trait IPragmaFeedsRegistryWrapper<TContractState> {
    /// Calls feed_exists from the Pragma Feeds Registry contract.
    fn call_feed_exists(self: @TContractState, feed_id: FeedId) -> bool;

    /// Calls get_all_feeds from the Pragma Feeds Registry contract.
    fn get_all_feeds(self: @TContractState) -> Array<FeedId>;
}

#[starknet::interface]
pub trait IHyperlaneMailboxWrapper<TContractState> {
    /// Calls dispatch from the Hyperlane Mailbox contract.
    fn call_dispatch(self: @TContractState, message_body: Bytes) -> HyperlaneMessageId;
}

#[starknet::interface]
pub trait IPragmaOracleWrapper<TContractState> {
    /// Calls get_data from the Pragma Oracle contract.
    fn call_get_data(
        self: @TContractState, data_type: DataType, aggregation_mode: AggregationMode,
    ) -> PragmaPricesResponse;
}

#[starknet::interface]
pub trait ISummaryStatsWrapper<TContractState> {
    /// Calls calculate_mean from the Summary Stats contract.
    fn call_calculate_mean(
        self: @TContractState,
        data_type: DataType,
        aggregation_mode: AggregationMode,
        start_timestamp: u64,
        end_timestamp: u64,
    ) -> SummaryStatsComputation;

    /// Calls calculate_volatility from the Summary Stats contract.
    fn call_calculate_volatility(
        self: @TContractState,
        data_type: DataType,
        aggregation_mode: AggregationMode,
        start_timestamp: u64,
        end_timestamp: u64,
        num_samples: u64,
    ) -> SummaryStatsComputation;

    /// Calls calculate_twap from the Summary Stats contract.
    fn call_calculate_twap(
        self: @TContractState,
        data_type: DataType,
        aggregation_mode: AggregationMode,
        start_timestamp: u64,
        duration: u64,
    ) -> SummaryStatsComputation;
}
