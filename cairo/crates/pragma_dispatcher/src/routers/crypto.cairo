#[starknet::contract]
pub mod CryptoRouter {
    use alexandria_bytes::{Bytes, BytesTrait};
    use core::num::traits::Zero;
    use core::panic_with_felt252;
    use pragma_dispatcher::routers::{
        errors, interface::{IAssetClassRouter, IPragmaOracleWrapper, ISummaryStatsWrapper}
    };
    use pragma_dispatcher::types::pragma_oracle::SummaryStatsComputation;
    use pragma_feed_types::{Feed, FeedTrait, FeedType};
    use pragma_lib::abi::{
        IPragmaABIDispatcher, IPragmaABIDispatcherTrait, ISummaryStatsABIDispatcher,
        ISummaryStatsABIDispatcherTrait
    };
    use pragma_lib::types::{PragmaPricesResponse, OptionsFeedData, DataType, AggregationMode};
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

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
        fn get_feed_update(self: @ContractState, feed: Feed) -> Bytes {
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
            let data_type = DataType::SpotEntry(feed.pair_id);
            let aggregation_mode = AggregationMode::Median;

            let response = self.call_get_data(data_type, aggregation_mode);

            let mut update = BytesTrait::new_empty();
            update.append_u256(feed.id().into());
            update.append_u64(response.last_updated_timestamp);
            update.append_u16(response.num_sources_aggregated.try_into().unwrap());
            update.append_u8(response.decimals.try_into().unwrap());
            update.append_u256(response.price.into());
            update.append_u256(0); // TODO: volume

            update
        }

        fn twap(self: @ContractState, feed: Feed) -> Bytes {
            let data_type = DataType::SpotEntry(feed.pair_id);
            let aggregation_mode = AggregationMode::Median;
            let start_timestamp = 1;
            let duration = 1;

            let (twap_price, decimals) = self
                .call_calculate_twap(data_type, aggregation_mode, start_timestamp, duration);

            let mut update = BytesTrait::new_empty();
            update.append_u256(feed.id().into());
            update.append_u64(start_timestamp); // TODO: timestamp
            update.append_u16(0); // TODO: number of sources
            update.append_u8(decimals.try_into().unwrap());
            update.append_u256(twap_price.into());
            update.append_u256(duration.into()); // TODO: time period
            update.append_u256(0); // TODO: start_price
            update.append_u256(0); // TODO: end_price
            update.append_u256(0); // TODO: total volume
            update.append_u256(0); // TODO: number of data points

            update
        }

        fn realized_volatility(self: @ContractState, feed: Feed) -> Bytes {
            let data_type = DataType::SpotEntry(feed.pair_id);
            let aggregation_mode = AggregationMode::Median;
            let start_timestamp = 1;
            let end_timestamp = 2;
            let num_samples = 10;

            let (volatility, decimals) = self
                .call_calculate_volatility(
                    data_type, aggregation_mode, start_timestamp, end_timestamp, num_samples
                );

            let mut update = BytesTrait::new_empty();
            update.append_u256(feed.id().into());
            update.append_u64(start_timestamp); // TODO: timestamp
            update.append_u16(0); // TODO: number of sources
            update.append_u8(decimals.try_into().unwrap());
            update.append_u256(volatility.into());
            update.append_u256(0); // TODO: time period
            update.append_u256(0); // TODO: start price
            update.append_u256(0); // TODO: end price
            update.append_u256(0); // TODO: high price
            update.append_u256(0); // TODO: low price
            update.append_u256(0); // TODO: number of data points

            update
        }

        fn option(self: @ContractState, feed: Feed) -> Bytes {
            let instrument_name = feed.pair_id;

            let response = self.call_get_options_data(instrument_name);

            let mut update = BytesTrait::new_empty();
            update.append_u256(feed.id().into());
            update.append_u64(response.current_timestamp);
            update.append_u16(1);
            update.append_u8(0); // TODO: decimals
            update.append_u256(0); // TODO: strike price
            update.append_u256(0); // TODO: implied volatility
            update.append_u256(0); // TODO: time to expiry <- from instrument_name
            update.append_u8(0); // TODO: is call <- from instrument_name
            update.append_u256(0); // TODO: underlying price
            update.append_u256(response.mark_price.into());
            update.append_u256(0); // TODO: delta
            update.append_u256(0); // TODO: gamma
            update.append_u256(0); // TODO: vega
            update.append_u256(0); // TODO: theta
            update.append_u256(0); // TODO: rho

            update
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

        /// Calls get_options_data from the Summary Stats contract.
        fn call_get_options_data(
            self: @ContractState, instrument_name: felt252,
        ) -> OptionsFeedData {
            self.summary_stats.read().get_options_data(instrument_name)
        }
    }
}
