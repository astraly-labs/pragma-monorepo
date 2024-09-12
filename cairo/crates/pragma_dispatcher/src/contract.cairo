#[starknet::contract]
mod PragmaDispatcher {
    use alexandria_bytes::Bytes;
    use core::num::traits::Zero;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::{interface::IUpgradeable, upgradeable::UpgradeableComponent};
    use pragma_dispatcher::interface::{
        IPragmaDispatcher, IHyperlaneMailboxWrapper, IPragmaOracleWrapper, ISummaryStatsWrapper,
    };
    use pragma_dispatcher::types::pragma_oracle::{
        PragmaPricesResponse, DataType, AggregationMode, SummaryStatsComputation
    };
    use pragma_feed_types::{FeedId};
    use starknet::ClassHash;
    use starknet::ContractAddress;

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

        /// Returns the list of supported feeds.
        fn supported_feeds(self: @ContractState) -> Span<FeedId> {
            array![].span()
        }

        /// Dispatch updates through the Hyperlane mailbox for the specified list
        /// of [Span<FeedId>].
        fn dispatch(self: @ContractState, feed_ids: Span<FeedId>) {}
    }

    // ================== COMPONENTS IMPLEMENTATIONS ==================

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    // ================== PRIVATE IMPLEMENTATIONS ==================

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(
            ref self: ContractState,
            owner: ContractAddress,
            pragma_oracle_address: ContractAddress,
            summary_stats_address: ContractAddress,
            pragma_feed_registry_address: ContractAddress,
            hyperlane_mailbox_address: ContractAddress,
        ) {
            // [Check]
            assert(!owner.is_zero(), 'Owner cannot be 0');

            // [Effect]
            self.ownable.initializer(owner);
            self.pragma_oracle_address.write(pragma_oracle_address);
            self.summary_stats_address.write(summary_stats_address);
            self.pragma_feed_registry_address.write(pragma_feed_registry_address);
            self.hyperlane_mailbox_address.write(hyperlane_mailbox_address);
        }
    }

    impl HyperlaneMailboxWrapper of IHyperlaneMailboxWrapper<ContractState> {
        /// Calls dispatch from the Hyperlane Mailbox.
        fn _call_dispatch(self: @ContractState, message_body: Bytes) {}
    }

    impl PragmaOracleWrapper of IPragmaOracleWrapper<ContractState> {
        /// Calls get_data from the Pragma Oracle.
        fn _call_get_data(
            self: @ContractState, data_type: DataType, aggregation_mode: AggregationMode,
        ) -> PragmaPricesResponse {
            PragmaPricesResponse {
                price: 0,
                decimals: 0,
                last_updated_timestamp: 0,
                num_sources_aggregated: 0,
                expiration_timestamp: Option::None(())
            }
        }
    }

    impl SummaryStatsWrapper of ISummaryStatsWrapper<ContractState> {
        /// Calls calculate_mean from the Summary Stats contract.
        fn _call_calculate_mean(
            self: @ContractState,
            data_type: DataType,
            aggregation_mode: AggregationMode,
            start_timestamp: u64,
            end_timestamp: u64,
        ) -> SummaryStatsComputation {
            (0, 0)
        }

        /// Calls calculate_volatility from the Summary Stats contract.
        fn _call_calculate_volatility(
            self: @ContractState,
            data_type: DataType,
            aggregation_mode: AggregationMode,
            start_timestamp: u64,
            end_timestamp: u64,
            num_samples: u64,
        ) -> SummaryStatsComputation {
            (0, 0)
        }

        /// Calls calculate_twap from the Summary Stats contract.
        fn _call_calculate_twap(
            self: @ContractState,
            data_type: DataType,
            aggregation_mode: AggregationMode,
            start_timestamp: u64,
            duration: u64,
        ) -> SummaryStatsComputation {
            (0, 0)
        }
    }
}
