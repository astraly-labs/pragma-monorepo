use core::num::traits::Zero;
use pragma_dispatcher::types::pragma_oracle::SummaryStatsComputation;
use pragma_feed_types::{FeedTypeId};
use pragma_lib::types::{PragmaPricesResponse, OptionsFeedData, DataType, AggregationMode};
use starknet::contract_address_const;

#[starknet::interface]
pub trait IFeedTypeRouter<TContractState> {
    /// Returns the feed type id of the current router.
    fn get_feed_type_id(self: @TContractState) -> FeedTypeId;
    /// Returns the update for the feed as bytes.
    fn get_data(self: @TContractState) -> alexandria_bytes::Bytes;
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

    /// Calls get_options_data from the Summary Stats contract.
    fn call_get_options_data(self: @TContractState, instrument_name: felt252,) -> OptionsFeedData;
}

impl IFeedTypeRouterZero of Zero<IFeedTypeRouterDispatcher> {
    fn zero() -> IFeedTypeRouterDispatcher {
        IFeedTypeRouterDispatcher { contract_address: contract_address_const::<0>() }
    }

    #[inline]
    fn is_zero(self: @IFeedTypeRouterDispatcher) -> bool {
        *self.contract_address == contract_address_const::<0>()
    }

    #[inline]
    fn is_non_zero(self: @IFeedTypeRouterDispatcher) -> bool {
        !self.is_zero()
    }
}
