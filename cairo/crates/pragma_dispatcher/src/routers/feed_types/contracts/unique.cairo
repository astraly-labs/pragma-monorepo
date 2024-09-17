#[starknet::contract]
pub mod FeedTypeUniqueRouter {
    use alexandria_bytes::{Bytes, BytesTrait};
    use core::num::traits::Zero;
    use core::panic_with_felt252;
    use pragma_dispatcher::routers::feed_types::{
        errors, interface::{IFeedTypeRouter, IPragmaOracleWrapper, ISummaryStatsWrapper}
    };
    use pragma_dispatcher::types::pragma_oracle::SummaryStatsComputation;
    use pragma_feed_types::{FeedType, FeedTypeId, FeedTypeTrait};
    use pragma_lib::abi::{
        IPragmaABIDispatcher, IPragmaABIDispatcherTrait, ISummaryStatsABIDispatcher,
        ISummaryStatsABIDispatcherTrait
    };
    use pragma_lib::types::{PragmaPricesResponse, OptionsFeedData, DataType, AggregationMode};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    // ================== STORAGE ==================

    #[storage]
    struct Storage {
        // Pragma Oracle contract
        pragma_oracle: IPragmaABIDispatcher,
        // Pragma Summary stats contract
        summary_stats: ISummaryStatsABIDispatcher,
        // Feed type of the current router
        feed_type: FeedType,
    }

    // ================== EVENTS ==================

    #[derive(starknet::Event, Drop)]
    pub struct FeedTypeRouterDeployed {
        pub sender: ContractAddress,
        pub feed_type_id: FeedTypeId,
        pub router_address: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        FeedTypeRouterDeployed: FeedTypeRouterDeployed
    }

    // ================== CONSTRUCTOR ================================

    #[constructor]
    fn constructor(
        ref self: ContractState,
        pragma_oracle_address: ContractAddress,
        summary_stats_address: ContractAddress,
        feed_type_id: FeedTypeId,
    ) {
        self.initializer(pragma_oracle_address, summary_stats_address, feed_type_id);
    }
    // ================== PUBLIC ABI ==================

    #[abi(embed_v0)]
    pub impl UniqueRouterImpl of IFeedTypeRouter<ContractState> {
        /// Returns the feed type id of the current router.
        fn get_feed_type_id(self: @ContractState) -> FeedTypeId {
            self.feed_type.read().id()
        }

        /// Returns the update for the feed as bytes.
        fn get_data(self: @ContractState) -> Bytes {
            BytesTrait::new_empty() // TODO
        }
    }


    // ================== PRIVATE IMPLEMENTATIONS ==================

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Initializes the contract storage.
        /// Called only once by the constructor.
        fn initializer(
            ref self: ContractState,
            pragma_oracle_address: ContractAddress,
            summary_stats_address: ContractAddress,
            feed_type_id: FeedTypeId,
        ) {
            // [Check] Contracts are not zero
            assert(!pragma_oracle_address.is_zero(), errors::PRAGMA_ORACLE_IS_ZERO);
            assert(!summary_stats_address.is_zero(), errors::SUMMARY_STATS_IS_ZERO);
            // [Check] Feed type id is valid
            let feed_type = match FeedTypeTrait::from_id(feed_type_id) {
                Result::Ok(f) => f,
                Result::Err(e) => panic_with_felt252(e.into())
            };

            // [Effect] Init components storages
            self.feed_type.write(feed_type);

            // [Interaction] Emit new router deployed
            self
                .emit(
                    FeedTypeRouterDeployed {
                        sender: get_caller_address(),
                        feed_type_id: feed_type_id,
                        router_address: get_contract_address(),
                    }
                )
        }
    }

    impl PragmaOracleWrapper of IPragmaOracleWrapper<ContractState> {
        /// Calls get_data from the Pragma Oracle contract.
        fn call_get_data(
            self: @ContractState, data_type: DataType, aggregation_mode: AggregationMode,
        ) -> PragmaPricesResponse {
            self.pragma_oracle.read().get_data(data_type, aggregation_mode)
        }
    }

    impl SummaryStatsWrapper of ISummaryStatsWrapper<ContractState> {
        /// Calls calculate_mean from the Summary Stats contract.
        fn call_calculate_mean(
            self: @ContractState,
            data_type: DataType,
            aggregation_mode: AggregationMode,
            start_timestamp: u64,
            end_timestamp: u64,
        ) -> SummaryStatsComputation {
            self
                .summary_stats
                .read()
                .calculate_mean(data_type, start_timestamp, end_timestamp, aggregation_mode)
        }

        /// Calls calculate_volatility from the Summary Stats contract.
        fn call_calculate_volatility(
            self: @ContractState,
            data_type: DataType,
            aggregation_mode: AggregationMode,
            start_timestamp: u64,
            end_timestamp: u64,
            num_samples: u64,
        ) -> SummaryStatsComputation {
            self
                .summary_stats
                .read()
                .calculate_volatility(
                    data_type, start_timestamp, end_timestamp, num_samples, aggregation_mode
                )
        }

        /// Calls calculate_twap from the Summary Stats contract.
        fn call_calculate_twap(
            self: @ContractState,
            data_type: DataType,
            aggregation_mode: AggregationMode,
            start_timestamp: u64,
            duration: u64,
        ) -> SummaryStatsComputation {
            self
                .summary_stats
                .read()
                .calculate_twap(data_type, aggregation_mode, duration, start_timestamp)
        }

        /// Calls get_options_data from the Summary Stats contract.
        fn call_get_options_data(
            self: @ContractState, instrument_name: felt252,
        ) -> OptionsFeedData {
            self.summary_stats.read().get_options_data(instrument_name)
        }
    }
}
