use alexandria_bytes::Bytes;
use core::num::traits::Zero;
use pragma_dispatcher::types::pragma_oracle::{SummaryStatsComputation};
use pragma_feed_types::Feed;
use pragma_lib::types::{PragmaPricesResponse, DataType, AggregationMode};
use starknet::contract_address_const;

#[starknet::interface]
pub trait IAssetClassRouter<TContractState> {
    fn routing(self: @TContractState, feed: Feed) -> Bytes;
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

impl IAssetClassRouterZero of Zero<IAssetClassRouterDispatcher> {
    fn zero() -> IAssetClassRouterDispatcher {
        IAssetClassRouterDispatcher { contract_address: contract_address_const::<0>() }
    }

    #[inline]
    fn is_zero(self: @IAssetClassRouterDispatcher) -> bool {
        *self.contract_address == contract_address_const::<0>()
    }

    #[inline]
    fn is_non_zero(self: @IAssetClassRouterDispatcher) -> bool {
        !self.is_zero()
    }
}
