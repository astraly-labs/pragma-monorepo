#[starknet::contract]
pub mod AssetClassRouter {
    use alexandria_bytes::{Bytes, BytesTrait};
    use core::num::traits::Zero;
    use core::panic_with_felt252;
    use pragma_dispatcher::routers::{
        errors, interface::{IAssetClassRouter, IPragmaOracleWrapper, ISummaryStatsWrapper}
    };
    use pragma_dispatcher::types::pragma_oracle::SummaryStatsComputation;
    use pragma_feed_types::{AssetClass, Feed, FeedTrait, FeedType};
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
        asset_class: AssetClass,
        feed_type_routers: Map<FeedType, Dispatcher>,
    }

    // ================== CONSTRUCTOR ================================

    #[constructor]
    fn constructor(ref self: ContractState, asset_class_id: AssetClassId,) {
        // [Check] Valid asset class id
        let asset_class: AssetClass = asset_class_id.try_into().unwrap(); // TODO: err

        // [Effect] Init storage
        self.asset_class_id.write(asset_class);
    }

    #[abi(embed_v0)]
    pub impl CryptoRouterImpl of IAssetClassRouter<ContractState> {
        fn get_feed_update(self: @ContractState, feed: Feed) -> Bytes {
            let feed_type = feed.feed_type;
            let feed_type_router = self.feed_type_router.entry(feed_type).read();

            // TODO: assert not zero

            feed_type_router.get_data()
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
