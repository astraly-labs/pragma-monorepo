#[starknet::contract]
pub mod PragmaDispatcher {
    use alexandria_bytes::{Bytes, BytesTrait};
    use core::num::traits::Zero;
    use core::panic_with_felt252;
    use hyperlane_starknet::interfaces::{IMailboxDispatcher, IMailboxDispatcherTrait};
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::{interface::IUpgradeable, upgradeable::UpgradeableComponent};
    use pragma_dispatcher::errors;
    use pragma_dispatcher::interface::{
        IPragmaDispatcher, IHyperlaneMailboxWrapper, IPragmaOracleWrapper, ISummaryStatsWrapper,
        IPragmaFeedsRegistryWrapper,
    };
    use pragma_dispatcher::types::{
        hyperlane::HyperlaneMessageId, pragma_oracle::SummaryStatsComputation,
    };
    use pragma_feed_types::{Feed, FeedTrait, FeedWithId, FeedId};
    use pragma_feeds_registry::{
        IPragmaFeedsRegistryDispatcher, IPragmaFeedsRegistryDispatcherTrait
    };
    use pragma_lib::abi::{
        IPragmaABIDispatcher, IPragmaABIDispatcherTrait, ISummaryStatsABIDispatcher,
        ISummaryStatsABIDispatcherTrait
    };
    use pragma_lib::types::{PragmaPricesResponse, AggregationMode, DataType};
    use starknet::{ContractAddress, ClassHash};

    // ================== COMPONENTS ==================

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    // ================== STORAGE ==================

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        // Pragma Oracle contract
        pragma_oracle_address: ContractAddress,
        // Pragma Summary stats contract
        summary_stats_address: ContractAddress,
        // Pragma Feed Registry containing all the supported feeds
        pragma_feed_registry_address: ContractAddress,
        // Hyperlane core contract
        hyperlane_mailbox_address: ContractAddress,
    }

    // ================== EVENTS ==================

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event
    }

    // ================== CONSTRUCTOR ================================

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        pragma_oracle_address: ContractAddress,
        summary_stats_address: ContractAddress,
        pragma_feed_registry_address: ContractAddress,
        hyperlane_mailbox_address: ContractAddress,
    ) {
        self
            .initializer(
                owner,
                pragma_oracle_address,
                summary_stats_address,
                pragma_feed_registry_address,
                hyperlane_mailbox_address
            );
    }

    // ================== PUBLIC ABI ==================

    #[abi(embed_v0)]
    impl PragmaDispatcher of IPragmaDispatcher<ContractState> {
        /// Returns the registered Pragma Oracle address.
        fn get_pragma_oracle_address(self: @ContractState) -> ContractAddress {
            self.pragma_oracle_address.read()
        }

        /// Returns the registered Pragma Feed Registry address.
        fn get_pragma_feed_registry_address(self: @ContractState) -> ContractAddress {
            self.pragma_feed_registry_address.read()
        }

        /// Returns the registered Hyperlane Mailbox address.
        fn get_hyperlane_mailbox_address(self: @ContractState) -> ContractAddress {
            self.hyperlane_mailbox_address.read()
        }

        fn get_feed(self: @ContractState, feed_id: FeedId) -> FeedWithId {
            self.call_get_feed(feed_id)
        }

        /// Returns the list of supported feeds.
        fn supported_feeds(self: @ContractState) -> Array<FeedId> {
            self.call_get_all_feeds()
        }

        /// Dispatch updates through the Hyperlane mailbox for the specified list
        /// of feed ids.
        ///
        /// The updates are dispatched through a Message, which format is:
        ///   - [u32] number of feeds updated,
        ///
        /// Steps:
        ///   1. Check that all feeds are valids. We are doing that because we need
        ///      to write the length of the feeds updated as the first element of
        ///      the hyperlane message, so we need to have a valid length.
        ///      Also, we don't want silent errors where one feed didn't get updated
        ///      and the user can't notice it directly.
        ///
        ///  2. For each feed, retrieve the latest data available and update the message.
        ///     This is done in the [add_feed_update_to_message] function.
        ///
        ///  3. Send the updates using the [dispatch] Hyperlane function.
        fn dispatch(self: @ContractState, feed_ids: Span<FeedId>) -> HyperlaneMessageId {
            // [Check] Assert that all feeds id are registered in the Registry
            self.assert_all_feeds_exists(feed_ids.clone());

            // [Effect] Add the number of feeds to update to the message
            let mut update_message = BytesTrait::new_empty();
            let nb_feeds_to_update: u32 = feed_ids.len();
            update_message.append_u32(nb_feeds_to_update);

            let mut idx = 0;
            loop {
                if idx >= nb_feeds_to_update {
                    break;
                }
                // [Effect] Add the feed update to the message
                self.add_feed_update_to_message(ref update_message, *feed_ids.at(idx));
                idx += 1;
            };

            // [Interaction] Send the complete message to Hyperlane's Mailbox
            self.call_dispatch(update_message)
        }
    }

    // ================== COMPONENTS IMPLEMENTATIONS ==================

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    // ================== PRIVATE CALLERS OF SUB CONTRACTS ==================

    impl PragmaFeedsRegistryWrapper of IPragmaFeedsRegistryWrapper<ContractState> {
        /// Calls feed_exists from the Pragma Feeds Registry contract.
        fn call_feed_exists(self: @ContractState, feed_id: FeedId) -> bool {
            let registry_dispatcher = IPragmaFeedsRegistryDispatcher {
                contract_address: self.pragma_feed_registry_address.read()
            };
            registry_dispatcher.feed_exists(feed_id)
        }

        /// Calls get_feed from the Pragma Feeds Registry contract.
        fn call_get_feed(self: @ContractState, feed_id: FeedId) -> FeedWithId {
            let registry_dispatcher = IPragmaFeedsRegistryDispatcher {
                contract_address: self.pragma_feed_registry_address.read()
            };
            registry_dispatcher.get_feed(feed_id)
        }

        /// Calls get_all_feeds from the Pragma Feeds Registry contract.
        fn call_get_all_feeds(self: @ContractState) -> Array<FeedId> {
            let registry_dispatcher = IPragmaFeedsRegistryDispatcher {
                contract_address: self.pragma_feed_registry_address.read()
            };
            registry_dispatcher.get_all_feeds()
        }
    }

    impl HyperlaneMailboxWrapper of IHyperlaneMailboxWrapper<ContractState> {
        /// Calls dispatch from the Hyperlane Mailbox contract.
        fn call_dispatch(self: @ContractState, message_body: Bytes) -> HyperlaneMessageId {
            let mailbox_dispatcher = IMailboxDispatcher {
                contract_address: self.hyperlane_mailbox_address.read()
            };

            mailbox_dispatcher
                .dispatch(
                    0_u32, // destination_domain
                    0_u256, // recipient_address
                    message_body,
                    0_u256, // fee_amount
                    Option::<Bytes>::None(()), // _custom_hook_metadata
                    Option::<ContractAddress>::None(()), // _custom_hook
                )
        }
    }

    impl PragmaOracleWrapper of IPragmaOracleWrapper<ContractState> {
        /// Calls get_data from the Pragma Oracle contract.
        fn call_get_data(
            self: @ContractState, data_type: DataType, aggregation_mode: AggregationMode,
        ) -> PragmaPricesResponse {
            let pragma_dispatcher = IPragmaABIDispatcher {
                contract_address: self.pragma_oracle_address.read()
            };

            pragma_dispatcher.get_data(data_type, aggregation_mode)
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
            let summary_stats_dispatcher = ISummaryStatsABIDispatcher {
                contract_address: self.summary_stats_address.read()
            };

            summary_stats_dispatcher
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
            let summary_stats_dispatcher = ISummaryStatsABIDispatcher {
                contract_address: self.summary_stats_address.read()
            };

            summary_stats_dispatcher
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
            let summary_stats_dispatcher = ISummaryStatsABIDispatcher {
                contract_address: self.summary_stats_address.read()
            };

            summary_stats_dispatcher
                .calculate_twap(data_type, aggregation_mode, duration, start_timestamp)
        }
    }

    // ================== PRIVATE IMPLEMENTATIONS ==================

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Initializes the contract storage.
        /// Called only once by the constructor.
        fn initializer(
            ref self: ContractState,
            owner: ContractAddress,
            pragma_oracle_address: ContractAddress,
            summary_stats_address: ContractAddress,
            pragma_feed_registry_address: ContractAddress,
            hyperlane_mailbox_address: ContractAddress,
        ) {
            // [Check] Owner is a valid address
            assert(!owner.is_zero(), errors::OWNER_IS_ZERO);

            // [Effect] Init contract storage
            self.ownable.initializer(owner);
            self.pragma_oracle_address.write(pragma_oracle_address);
            self.summary_stats_address.write(summary_stats_address);
            self.pragma_feed_registry_address.write(pragma_feed_registry_address);
            self.hyperlane_mailbox_address.write(hyperlane_mailbox_address);
        }

        /// Checks that all feed ids provided in the [Span] are actually registered in
        /// the Feeds Registry contract.
        /// NOTE: The provided Span will get consumed.
        fn assert_all_feeds_exists(self: @ContractState, mut feed_ids: Span<FeedId>) {
            loop {
                match feed_ids.pop_front() {
                    Option::Some(v) => assert(
                        self.call_feed_exists(*v), errors::FEED_NOT_REGISTERED
                    ),
                    Option::None(()) => { break; }
                }
            };
        }

        /// Retrieves the latest data available for the provided [feed_id] and
        /// adds the data to the [message].
        fn add_feed_update_to_message(self: @ContractState, ref message: Bytes, feed_id: FeedId) {
            let _feed: Feed = match FeedTrait::from_id(feed_id) {
                Result::Ok(f) => f,
                Result::Err(e) => {
                    // This should NEVER happen as we have a check in the Feeds Registry.
                    panic_with_felt252(e.into())
                }
            };
        }
    }
}
