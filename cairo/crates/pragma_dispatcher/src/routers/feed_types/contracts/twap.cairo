#[starknet::contract]
pub mod FeedTypeTwapRouter {
    use alexandria_bytes::{Bytes, BytesTrait};
    use core::num::traits::Zero;
    use core::panic_with_felt252;
    use pragma_dispatcher::routers::feed_types::{errors, interface::{IFeedTypeRouter}};
    use pragma_dispatcher::types::pragma_oracle::{
        SimpleDataType, AggregationMode, SummaryStatsComputation, Duration, DurationTrait,
    };
    use pragma_feed_types::feed_type::{TwapVariant};
    use pragma_feed_types::{Feed, FeedTrait, FeedType, FeedTypeId, FeedTypeTrait};
    use pragma_lib::abi::{ISummaryStatsABIDispatcher, ISummaryStatsABIDispatcherTrait};
    use pragma_lib::types::DataType;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};

    // ================== STORAGE ==================

    #[storage]
    struct Storage {
        // Pragma Summary stats contract
        summary_stats: ISummaryStatsABIDispatcher,
        // Feed type of the current router
        feed_type: FeedType,
        // Data Type of the current feed type contract
        simple_data_type: SimpleDataType,
        // Aggregation of the current feed type contract
        aggregation_mode: AggregationMode,
        // Duration of the current feed type contract
        duration: Duration,
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
        ref self: ContractState, summary_stats_address: ContractAddress, feed_type_id: FeedTypeId,
    ) {
        self.initializer(summary_stats_address, feed_type_id);
    }
    // ================== PUBLIC ABI ==================

    #[abi(embed_v0)]
    pub impl TwapRouterImpl of IFeedTypeRouter<ContractState> {
        /// Returns the feed type id of the current router.
        fn get_feed_type_id(self: @ContractState) -> FeedTypeId {
            self.feed_type.read().id()
        }

        /// Returns the update for the feed as bytes.
        fn get_data(self: @ContractState, feed: Feed) -> Bytes {
            let pair_id = feed.pair_id;
            let data_type = match self.simple_data_type.read() {
                SimpleDataType::Spot => DataType::SpotEntry(pair_id),
                SimpleDataType::Perp => DataType::FutureEntry((pair_id, 0))
            };
            let aggregation_mode = self.aggregation_mode.read();
            let duration = self.duration.read().as_seconds();
            let start_timestamp = get_block_timestamp() - duration;

            let (twap_price, decimals) = self
                .call_calculate_twap(data_type, aggregation_mode, start_timestamp, duration);

            let mut update = BytesTrait::new_empty();
            update.append_u256(feed.id().unwrap().into());
            update.append_u64(get_block_timestamp());
            update.append_u16(0); // TODO: num sources ?
            update.append_u8(decimals.try_into().unwrap());
            update.append_u256(twap_price.into());
            update.append_u256(0); // TODO: time period ?
            update.append_u256(0); // TODO: start price ?
            update.append_u256(0); // TODO: end price ?
            update.append_u256(0); // TODO: total volume ?
            update.append_u256(0); // TODO: number of data points ?

            update
        }
    }


    // ================== PRIVATE IMPLEMENTATIONS ==================

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Initializes the contract storage.
        /// Called only once by the constructor.
        fn initializer(
            ref self: ContractState,
            summary_stats_address: ContractAddress,
            feed_type_id: FeedTypeId,
        ) {
            // [Check] Contracts are not zero
            assert(!summary_stats_address.is_zero(), errors::SUMMARY_STATS_IS_ZERO);

            // [Check] Feed type id is valid
            let feed_type = match FeedTypeTrait::from_id(feed_type_id) {
                Result::Ok(f) => f,
                Result::Err(e) => panic_with_felt252(e.into())
            };
            // [Check] Feed type variant & extract parameters
            let (simple_data_type, aggregation_mode, duration) = match feed_type {
                FeedType::Twap(variant) => {
                    match variant {
                        TwapVariant::SpotMedianOneDay => {
                            (SimpleDataType::Spot, AggregationMode::Median, Duration::OneDay)
                        },
                    }
                },
                _ => panic_with_felt252(errors::INVALID_FEED_TYPE_FOR_CONTRACT)
            };

            // [Effect] Save feed type to storage
            self.feed_type.write(feed_type);
            // [Effect] Set parameters depending on the variant
            self.simple_data_type.write(simple_data_type);
            self.aggregation_mode.write(aggregation_mode);
            self.duration.write(duration);

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
                .calculate_twap(data_type, aggregation_mode.into(), duration, start_timestamp)
        }
    }
}
