use alexandria_bytes::Bytes;
use pragma_dispatcher::types::pragma_oracle::{
    SummaryStatsComputation, PragmaPricesResponse, DataType, AggregationMode
};
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

    /// Dispatch updates through the Hyperlane mailbox for the specifieds
    /// [Span<FeedId>].
    fn dispatch(self: @TContractState, feed_ids: Span<FeedId>);
}

#[starknet::interface]
pub trait IHyperlaneMailboxWrapper<TContractState> {
    /// Calls dispatch from the Hyperlane Mailbox contract.
    fn _call_dispatch(self: @TContractState, message_body: Bytes);
}

#[starknet::interface]
pub trait IPragmaOracleWrapper<TContractState> {
    /// Calls get_data from the Pragma Oracle contract.
    fn _call_get_data(
        self: @TContractState, data_type: DataType, aggregation_mode: AggregationMode,
    ) -> PragmaPricesResponse;
}

#[starknet::interface]
pub trait ISummaryStatsWrapper<TContractState> {
    /// Calls calculate_mean from the Summary Stats contract.
    fn _call_calculate_mean(
        self: @TContractState,
        data_type: DataType,
        aggregation_mode: AggregationMode,
        start_timestamp: u64,
        end_timestamp: u64,
    ) -> SummaryStatsComputation;

    /// Calls calculate_volatility from the Summary Stats contract.
    fn _call_calculate_volatility(
        self: @TContractState,
        data_type: DataType,
        aggregation_mode: AggregationMode,
        start_timestamp: u64,
        end_timestamp: u64,
        num_samples: u64,
    ) -> SummaryStatsComputation;

    /// Calls calculate_twap from the Summary Stats contract.
    fn _call_calculate_twap(
        self: @TContractState,
        data_type: DataType,
        aggregation_mode: AggregationMode,
        start_timestamp: u64,
        duration: u64,
    ) -> SummaryStatsComputation;
}
