use pragma_entry::structures::{AggregationMode, DataType, OptionsFeedData};
use starknet::ContractAddress;

pub const DERIBIT_OPTIONS_FEED_ID: felt252 = 'DERIBIT_OPTIONS_MERKLE_ROOT';


#[starknet::interface]
pub trait ISummaryStatsABI<TContractState> {
    fn calculate_mean(
        self: @TContractState,
        data_type: DataType,
        start: u64,
        stop: u64,
        aggregation_mode: AggregationMode
    ) -> (u128, u32);

    fn update_options_data(
        ref self: TContractState, merkle_proof: Span<felt252>, update_data: OptionsFeedData
    ) -> OptionsFeedData;

    fn calculate_volatility(
        self: @TContractState,
        data_type: DataType,
        start_tick: u64,
        end_tick: u64,
        num_samples: u64,
        aggregation_mode: AggregationMode
    ) -> (u128, u32);

    fn calculate_twap(
        self: @TContractState,
        data_type: DataType,
        aggregation_mode: AggregationMode,
        time: u64,
        start_time: u64,
    ) -> (u128, u32);


    fn get_oracle_address(self: @TContractState) -> ContractAddress;

    fn get_options_data(self: @TContractState, instrument_name: felt252) -> OptionsFeedData;
    fn get_options_data_hash(self: @TContractState, update_data: OptionsFeedData) -> felt252;
}
