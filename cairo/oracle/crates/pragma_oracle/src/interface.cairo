use pragma_entry::structures::{
    DataType, PragmaPricesResponse, AggregationMode, PossibleEntries, Checkpoint, Currency, Pair,
    SimpleDataType
};
use starknet::{ContractAddress};

#[starknet::interface]
pub trait IOracleABI<TContractState> {
    fn get_decimals(self: @TContractState, data_type: DataType) -> u32;
    fn get_data_median(self: @TContractState, data_type: DataType) -> PragmaPricesResponse;
    fn get_data_median_for_sources(
        self: @TContractState, data_type: DataType, sources: Span<felt252>
    ) -> PragmaPricesResponse;
    fn get_data(
        self: @TContractState, data_type: DataType, aggregation_mode: AggregationMode
    ) -> PragmaPricesResponse;
    fn get_data_median_multi(
        self: @TContractState, data_types: Span<DataType>, sources: Span<felt252>
    ) -> Span<PragmaPricesResponse>;
    fn get_data_entry(
        self: @TContractState, data_type: DataType, source: felt252, publisher: felt252
    ) -> PossibleEntries;
    fn get_data_entry_for_publishers(
        self: @TContractState, data_type: DataType, source: felt252
    ) -> PossibleEntries;
    fn get_data_for_sources(
        self: @TContractState,
        data_type: DataType,
        aggregation_mode: AggregationMode,
        sources: Span<felt252>
    ) -> PragmaPricesResponse;
    fn get_data_entries(self: @TContractState, data_type: DataType) -> Span<PossibleEntries>;
    fn get_data_entries_for_sources(
        self: @TContractState, data_type: DataType, sources: Span<felt252>
    ) -> (Span<PossibleEntries>, u64);
    fn get_last_checkpoint_before(
        self: @TContractState,
        data_type: DataType,
        timestamp: u64,
        aggregation_mode: AggregationMode,
    ) -> (Checkpoint, u64);
    fn get_data_with_USD_hop(
        self: @TContractState,
        base_currency_id: felt252,
        quote_currency_id: felt252,
        aggregation_mode: AggregationMode,
        typeof: SimpleDataType,
        expiration_timestamp: Option::<u64>
    ) -> PragmaPricesResponse;
    fn get_publisher_registry_address(self: @TContractState) -> ContractAddress;
    fn get_latest_checkpoint_index(
        self: @TContractState, data_type: DataType, aggregation_mode: AggregationMode
    ) -> (u64, bool);
    fn get_latest_checkpoint(
        self: @TContractState, data_type: DataType, aggregation_mode: AggregationMode
    ) -> Checkpoint;
    fn get_checkpoint(
        self: @TContractState,
        data_type: DataType,
        checkpoint_index: u64,
        aggregation_mode: AggregationMode
    ) -> Checkpoint;
    fn get_sources_threshold(self: @TContractState,) -> u32;
    fn get_all_publishers(self: @TContractState, data_type: DataType) -> Span<felt252>;
    fn get_all_sources(self: @TContractState, data_type: DataType) -> Span<felt252>;
    fn publish_data(ref self: TContractState, new_entry: PossibleEntries);
    fn publish_data_entries(ref self: TContractState, new_entries: Span<PossibleEntries>);
    fn update_publisher_registry_address(
        ref self: TContractState, new_publisher_registry_address: ContractAddress
    );
    fn add_currency(ref self: TContractState, new_currency: Currency);
    fn update_currency(ref self: TContractState, currency_id: felt252, currency: Currency);
    fn get_currency(self: @TContractState, currency_id: felt252) -> Currency;
    fn update_pair(ref self: TContractState, pair_id: felt252, pair: Pair);
    fn add_pair(ref self: TContractState, new_pair: Pair);
    fn get_pair(self: @TContractState, pair_id: felt252) -> Pair;
    fn set_checkpoint(
        ref self: TContractState, data_type: DataType, aggregation_mode: AggregationMode
    );
    fn set_checkpoints(
        ref self: TContractState, data_types: Span<DataType>, aggregation_mode: AggregationMode
    );
    // fn remove_source(ref self: TContractState, source: felt252, data_type: DataType) -> bool;
    fn set_sources_threshold(ref self: TContractState, threshold: u32);
}

#[starknet::interface]
pub trait IPragmaABI<TContractState> {
    fn get_decimals(self: @TContractState, data_type: DataType) -> u32;

    fn get_data_median(self: @TContractState, data_type: DataType) -> PragmaPricesResponse;

    fn get_data_median_for_sources(
        self: @TContractState, data_type: DataType, sources: Span<felt252>
    ) -> PragmaPricesResponse;

    fn get_data(
        self: @TContractState, data_type: DataType, aggregation_mode: AggregationMode
    ) -> PragmaPricesResponse;

    fn get_data_entry(
        self: @TContractState, data_type: DataType, source: felt252, publisher: felt252
    ) -> PossibleEntries;
    fn get_data_entry_for_publishers(
        self: @TContractState, data_type: DataType, source: felt252
    ) -> PossibleEntries;

    fn get_data_for_sources(
        self: @TContractState,
        data_type: DataType,
        aggregation_mode: AggregationMode,
        sources: Span<felt252>
    ) -> PragmaPricesResponse;

    fn get_data_entries_for_sources(
        self: @TContractState, data_type: DataType, sources: Span<felt252>
    ) -> (Span<PossibleEntries>, u64);

    fn get_data_median_multi(
        self: @TContractState, data_types: Span<DataType>, sources: Span<felt252>
    ) -> Span<PragmaPricesResponse>;


    fn get_data_entries(self: @TContractState, data_type: DataType) -> Span<PossibleEntries>;

    fn get_last_checkpoint_before(
        self: @TContractState,
        data_type: DataType,
        timestamp: u64,
        aggregation_mode: AggregationMode,
    ) -> (Checkpoint, u64);

    fn get_data_with_USD_hop(
        self: @TContractState,
        base_currency_id: felt252,
        quote_currency_id: felt252,
        aggregation_mode: AggregationMode,
        typeof: SimpleDataType,
        expiration_timestamp: Option::<u64>
    ) -> PragmaPricesResponse;

    fn get_latest_checkpoint(
        self: @TContractState, data_type: DataType, aggregation_mode: AggregationMode
    ) -> Checkpoint;

    fn get_latest_checkpoint_index(
        self: @TContractState, data_type: DataType, aggregation_mode: AggregationMode
    ) -> (u64, bool);
    fn get_all_publishers(self: @TContractState, data_type: DataType) -> Span<felt252>;
    fn get_all_sources(self: @TContractState, data_type: DataType) -> Span<felt252>;
}
