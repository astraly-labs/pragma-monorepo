#[starknet::contract]
pub mod CryptoRouter {
    use alexandria_bytes::{Bytes, BytesTrait};
    use core::num::traits::Zero;
    use core::panic_with_felt252;
    use pragma_dispatcher::routers::{
        errors, interface::{IAssetClassRouter, IPragmaOracleWrapper, ISummaryStatsWrapper}
    };
    use pragma_dispatcher::types::pragma_oracle::{SummaryStatsComputation};
    use pragma_feed_types::{Feed, FeedType};
    use pragma_lib::abi::{
        IPragmaABIDispatcher, IPragmaABIDispatcherTrait, ISummaryStatsABIDispatcher,
        ISummaryStatsABIDispatcherTrait
    };
    use pragma_lib::types::{PragmaPricesResponse, DataType, AggregationMode};
    use starknet::ContractAddress;

    // ================== STORAGE ==================

    #[storage]
    struct Storage {
        // Pragma Oracle contract
        pragma_oracle: IPragmaABIDispatcher,
        // Pragma Summary stats contract
        summary_stats: ISummaryStatsABIDispatcher,
    }

    // ================== CONSTRUCTOR ================================

    #[constructor]
    fn constructor(
        ref self: ContractState,
        pragma_oracle_address: ContractAddress,
        summary_stats_address: ContractAddress
    ) {
        // [Check]
        assert(!pragma_oracle_address.is_zero(), errors::PRAGMA_ORACLE_IS_ZERO);
        assert(!summary_stats_address.is_zero(), errors::SUMMARY_STATS_IS_ZERO);

        // [Effect]
        let pragma_oracle = IPragmaABIDispatcher { contract_address: pragma_oracle_address };
        self.pragma_oracle.write(pragma_oracle);
        let summary_stats = ISummaryStatsABIDispatcher { contract_address: summary_stats_address };
        self.summary_stats.write(summary_stats);
    }

    #[abi(embed_v0)]
    pub impl CryptoRouterImpl of IAssetClassRouter<ContractState> {
        fn routing(self: @ContractState, feed: Feed) -> Bytes {
            match feed.feed_type {
                FeedType::SpotMedian => self.spot_median(feed),
                FeedType::Twap => self.twap(feed),
                FeedType::RealizedVolatility => self.realized_volatility(feed),
                FeedType::Option => self.option(feed),
                FeedType::Perp => self.perp(feed),
                _ => panic_with_felt252(errors::UNSUPPORTED_FEED_TYPE)
            }
        }
    }

    #[generate_trait]
    pub impl CryptoRouterInternal of ICryptoRouterInternal {
        fn initializer(ref self: ContractState,) {}

        fn spot_median(self: @ContractState, feed: Feed) -> Bytes {
            BytesTrait::new_empty()
        }

        fn twap(self: @ContractState, feed: Feed) -> Bytes {
            BytesTrait::new_empty()
        }

        fn realized_volatility(self: @ContractState, feed: Feed) -> Bytes {
            BytesTrait::new_empty()
        }

        fn option(self: @ContractState, feed: Feed) -> Bytes {
            BytesTrait::new_empty()
        }

        fn perp(self: @ContractState, feed: Feed) -> Bytes {
            BytesTrait::new_empty()
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
    }
}
