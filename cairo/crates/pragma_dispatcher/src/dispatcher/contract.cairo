#[starknet::contract]
pub mod PragmaDispatcher {
    use alexandria_bytes::{Bytes, BytesTrait};
    use core::num::traits::Zero;
    use core::panic_with_felt252;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::{interface::IUpgradeable, upgradeable::UpgradeableComponent};
    use pragma_dispatcher::dispatcher::errors;
    use pragma_dispatcher::dispatcher::interface::{
        IPragmaDispatcher, IHyperlaneMailboxWrapper, IPragmaFeedsRegistryWrapper,
    };
    use pragma_dispatcher::routers::{IAssetClassRouterDispatcher, IAssetClassRouterDispatcherTrait};
    use pragma_dispatcher::types::hyperlane::{IMailboxDispatcher, IMailboxDispatcherTrait};
    use pragma_dispatcher::types::{hyperlane::HyperlaneMessageId};
    use pragma_feed_types::{Feed, FeedTrait, FeedWithId, FeedId, AssetClass, AssetClassId};
    use pragma_feeds_registry::{
        IPragmaFeedsRegistryDispatcher, IPragmaFeedsRegistryDispatcherTrait
    };
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map
    };
    use starknet::{ContractAddress, ClassHash, get_caller_address};

    // ================== COMPONENTS ==================

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

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
        // Pragma Feed Registry containing all the supported feeds
        pragma_feed_registry: IPragmaFeedsRegistryDispatcher,
        // Hyperlane mailbox contract
        hyperlane_mailbox: IMailboxDispatcher,
        // Feed routers for each asset class
        routers: Map<AssetClass, IAssetClassRouterDispatcher>,
    }

    // ================== EVENTS ==================

    #[derive(starknet::Event, Drop)]
    pub struct RouterUpdated {
        pub sender: ContractAddress,
        pub asset_class_id: AssetClassId,
        pub router_address: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        RouterUpdated: RouterUpdated
    }

    // ================== CONSTRUCTOR ================================

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        pragma_feed_registry_address: ContractAddress,
        hyperlane_mailbox_address: ContractAddress,
    ) {
        self.initializer(owner, pragma_feed_registry_address, hyperlane_mailbox_address);
    }

    // ================== PUBLIC ABI ==================

    #[abi(embed_v0)]
    impl PragmaDispatcher of IPragmaDispatcher<ContractState> {
        /// Returns the registered Pragma Feed Registry address.
        fn get_pragma_feed_registry_address(self: @ContractState) -> ContractAddress {
            self.pragma_feed_registry.read().contract_address
        }

        /// Returns the registered Hyperlane Mailbox address.
        fn get_hyperlane_mailbox_address(self: @ContractState) -> ContractAddress {
            self.hyperlane_mailbox.read().contract_address
        }

        fn get_feed(self: @ContractState, feed_id: FeedId) -> FeedWithId {
            self.call_get_feed(feed_id)
        }

        /// Returns the list of supported feeds.
        fn supported_feeds(self: @ContractState) -> Array<FeedId> {
            self.call_get_all_feeds()
        }

        /// Register a new router for an Asset Class.
        fn register_router(
            ref self: ContractState, asset_class_id: AssetClassId, router_address: ContractAddress,
        ) {
            // [Check] Only owner
            self.ownable.assert_only_owner();
            // [Check] Valid asset class
            let asset_class: Option<AssetClass> = asset_class_id.try_into();
            assert(asset_class.is_some(), errors::UNKNOWN_ASSET_CLASS);

            // [Effect] Update the router for the given asset class
            let router = IAssetClassRouterDispatcher { contract_address: router_address };
            self.routers.entry(asset_class.unwrap()).write(router);

            // [Interaction] Storage updated event
            self
                .emit(
                    RouterUpdated {
                        sender: get_caller_address(),
                        asset_class_id: asset_class_id,
                        router_address: router_address,
                    }
                )
        }

        /// Dispatch updates through the Hyperlane mailbox for the specified list
        /// of feed ids.
        ///
        /// The updates are dispatched through a Message, which format is:
        ///   - [u32] number of feeds updated,
        ///   - [X bytes] update per message. The number of bytes sent depends
        ///     for each type of asset_class->feed_type.
        ///     Check the Pragma documentation for more information.
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

            // [Effect] For each feed, add the update to the message
            for feed_id in feed_ids {
                self.add_feed_update_to_message(ref update_message, *feed_id);
            };

            // [Interaction] Send the complete message to Hyperlane's Mailbox
            self.call_dispatch(update_message)
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
            pragma_feed_registry_address: ContractAddress,
            hyperlane_mailbox_address: ContractAddress,
        ) {
            // [Check] Addresses are valid
            assert(!owner.is_zero(), errors::OWNER_IS_ZERO);
            assert(!pragma_feed_registry_address.is_zero(), errors::PRAGMA_FEED_REGISTRY_IS_ZERO);
            assert(!hyperlane_mailbox_address.is_zero(), errors::HYPERLANE_MAILBOX_IS_ZERO);

            // [Effect] Init components storages
            self.ownable.initializer(owner);

            // [Effect] Init contract storage
            let pragma_feeds_registry = IPragmaFeedsRegistryDispatcher {
                contract_address: pragma_feed_registry_address
            };
            self.pragma_feed_registry.write(pragma_feeds_registry);

            let hyperlane_mailbox = IMailboxDispatcher {
                contract_address: hyperlane_mailbox_address
            };
            self.hyperlane_mailbox.write(hyperlane_mailbox);
        }

        /// Checks that all feed ids provided in the [Span] are actually registered in
        /// the Feeds Registry contract.
        fn assert_all_feeds_exists(self: @ContractState, feed_ids: Span<FeedId>) {
            for feed_id in feed_ids {
                assert(self.call_feed_exists(*feed_id), errors::FEED_NOT_REGISTERED)
            };
        }

        /// Retrieves the latest data available for the provided [feed_id] and
        /// adds the data to the [message].
        fn add_feed_update_to_message(self: @ContractState, ref message: Bytes, feed_id: FeedId) {
            // [Check] Feed id is valid
            let feed: Feed = match FeedTrait::from_id(feed_id) {
                Result::Ok(f) => f,
                Result::Err(e) => { panic_with_felt252(e.into()) }
            };

            // [Check] Feed's asset class router is registered
            let router = self.routers.entry(feed.asset_class).read();
            assert(!router.is_zero(), errors::NO_ROUTER_REGISTERED);

            // [Effect] Retrieve the feed update and add it to the message
            let feed_update_message = router.get_feed_update(feed);
            message.concat(@feed_update_message);
        }
    }

    // ================== PRIVATE CALLERS OF SUB CONTRACTS ==================

    impl PragmaFeedsRegistryWrapper of IPragmaFeedsRegistryWrapper<ContractState> {
        /// Calls feed_exists from the Pragma Feeds Registry contract.
        fn call_feed_exists(self: @ContractState, feed_id: FeedId) -> bool {
            self.pragma_feed_registry.read().feed_exists(feed_id)
        }

        /// Calls get_feed from the Pragma Feeds Registry contract.
        fn call_get_feed(self: @ContractState, feed_id: FeedId) -> FeedWithId {
            self.pragma_feed_registry.read().get_feed(feed_id)
        }

        /// Calls get_all_feeds from the Pragma Feeds Registry contract.
        fn call_get_all_feeds(self: @ContractState) -> Array<FeedId> {
            self.pragma_feed_registry.read().get_all_feeds()
        }
    }

    impl HyperlaneMailboxWrapper of IHyperlaneMailboxWrapper<ContractState> {
        /// Calls dispatch from the Hyperlane Mailbox contract.
        fn call_dispatch(self: @ContractState, message_body: Bytes) -> HyperlaneMessageId {
            self
                .hyperlane_mailbox
                .read()
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

    // ================== COMPONENTS IMPLEMENTATIONS ==================

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }
}
