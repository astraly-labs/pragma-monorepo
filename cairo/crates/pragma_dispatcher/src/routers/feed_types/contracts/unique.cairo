#[starknet::contract]
pub mod FeedTypeUniqueRouter {
    use alexandria_bytes::{Bytes, BytesTrait};
    use core::num::traits::Zero;
    use core::panic_with_felt252;
    use pragma_dispatcher::routers::feed_types::{errors, interface::IFeedTypeRouter};
    use pragma_dispatcher::types::pragma_oracle::{SimpleDataType, AggregationMode};
    use pragma_feed_types::feed_type::{UniqueVariant};
    use pragma_feed_types::{Feed, FeedTrait, FeedType, FeedTypeId, FeedTypeTrait};
    use pragma_lib::abi::{IPragmaABIDispatcher, IPragmaABIDispatcherTrait,};
    use pragma_lib::types::{PragmaPricesResponse, DataType};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    // ================== STORAGE ==================

    #[storage]
    struct Storage {
        // Pragma Oracle contract
        pragma_oracle: IPragmaABIDispatcher,
        // Feed type of the current router
        feed_type: FeedType,
        // Data Type of the current feed type contract
        simple_data_type: SimpleDataType,
        // Aggregation of the current feed type contract
        aggregation_mode: AggregationMode,
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
        ref self: ContractState, pragma_oracle_address: ContractAddress, feed_type_id: FeedTypeId,
    ) {
        self.initializer(pragma_oracle_address, feed_type_id);
    }
    // ================== PUBLIC ABI ==================

    #[abi(embed_v0)]
    pub impl UniqueRouterImpl of IFeedTypeRouter<ContractState> {
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

            let response = self.call_get_data(data_type, aggregation_mode);

            let mut update = BytesTrait::new_empty();
            update.append_u256(feed.id().unwrap().into());
            update.append_u64(response.last_updated_timestamp);
            update.append_u16(response.num_sources_aggregated.try_into().unwrap());
            update.append_u8(response.decimals.try_into().unwrap());
            update.append_u256(response.price.into());
            update.append_u256(0); // TODO: volume?

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
            pragma_oracle_address: ContractAddress,
            feed_type_id: FeedTypeId,
        ) {
            // [Check] Contracts are not zero
            assert(!pragma_oracle_address.is_zero(), errors::PRAGMA_ORACLE_IS_ZERO);

            // [Check] Feed type id is valid
            let feed_type = match FeedTypeTrait::from_id(feed_type_id) {
                Result::Ok(f) => f,
                Result::Err(e) => panic_with_felt252(e.into())
            };
            // [Check] Feed type variant & extract parameters
            let (simple_data_type, aggregation_mode) = match feed_type {
                FeedType::Unique(variant) => {
                    match variant {
                        UniqueVariant::SpotMedian => {
                            (SimpleDataType::Spot, AggregationMode::Median)
                        },
                        UniqueVariant::PerpMedian => {
                            (SimpleDataType::Perp, AggregationMode::Median)
                        },
                        UniqueVariant::SpotMean => { (SimpleDataType::Spot, AggregationMode::Mean) }
                    }
                },
                _ => panic_with_felt252(errors::INVALID_FEED_TYPE_FOR_CONTRACT)
            };

            // [Effect] Save feed type to storage
            self.feed_type.write(feed_type);
            // [Effect] Set parameters depending on the variant
            self.simple_data_type.write(simple_data_type);
            self.aggregation_mode.write(aggregation_mode);

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

        /// Calls get_data from the Pragma Oracle contract.
        fn call_get_data(
            self: @ContractState, data_type: DataType, aggregation_mode: AggregationMode,
        ) -> PragmaPricesResponse {
            self.pragma_oracle.read().get_data(data_type, aggregation_mode.into())
        }
    }
}
