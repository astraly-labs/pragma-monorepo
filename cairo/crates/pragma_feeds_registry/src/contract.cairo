#[starknet::contract]
pub mod PragmaFeedRegistry {
    use core::num::traits::Zero;
    use core::panic_with_felt252;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::{UpgradeableComponent, interface::IUpgradeable};
    use pragma_feed_types::{FeedId, FeedTrait};
    use pragma_feeds_registry::errors;
    use pragma_feeds_registry::interface::IPragmaFeedRegistry;
    use starknet::{ClassHash, ContractAddress, get_caller_address};

    // ================== COMPONENTS ==================

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    // ================== STORAGE ==================

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        // Total feed ids registered
        len_feed_ids: u32,
        // All supported feed ids
        feed_ids: LegacyMap::<u32, FeedId>
    }

    // ================== EVENTS ==================

    #[derive(starknet::Event, Drop)]
    pub struct NewFeedId {
        pub sender: ContractAddress,
        pub feed_id: felt252,
    }

    #[derive(starknet::Event, Drop)]
    pub struct RemovedFeedId {
        pub sender: ContractAddress,
        pub feed_id: felt252,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        NewFeedId: NewFeedId,
        RemovedFeedId: RemovedFeedId
    }
    // ================== CONSTRUCTOR ================================

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        // [Check]
        assert(!owner.is_zero(), errors::OWNER_IS_ZERO);
        // [Effect]
        self.ownable.initializer(owner);
    }

    // ================== PUBLIC ABI ==================

    #[abi(embed_v0)]
    impl PragmaFeedRegistry of IPragmaFeedRegistry<ContractState> {
        /// Adds the [feed_id] into the Registry.
        ///
        /// Panics if:
        ///     * the feed_id format is incorrect,
        ///     * the feed_id is already registered.
        fn add_feed(ref self: ContractState, feed_id: FeedId) {
            // [Check] Only owner
            self.ownable.assert_only_owner();
            // [Check] Feed id not already registered
            assert(!self.feed_exists(feed_id), errors::FEED_ALREADY_REGISTERED);
            // [Check] Feed id format
            match FeedTrait::from_id(feed_id) {
                Result::Ok(_) => {},
                Result::Err(e) => panic_with_felt252(e.into())
            };

            // [Effect] Insert new feed id
            let len_feed_ids = self.len_feed_ids.read();
            self.feed_ids.write(len_feed_ids, feed_id);
            self.len_feed_ids.write(len_feed_ids + 1);

            // [Interaction] Event emitted
            self.emit(NewFeedId { sender: get_caller_address(), feed_id: feed_id, })
        }

        /// Removes the [feed_id] from the Registry.
        ///
        /// Panics if the feed_id is not in the Registry.
        fn remove_feed(ref self: ContractState, feed_id: FeedId) {
            // [Check] Only owner
            self.ownable.assert_only_owner();
            // [Check] Feed id registered
            let feed_id_index: Option<u32> = self.get_feed_id_index(feed_id);
            assert(feed_id_index.is_some(), errors::FEED_NOT_REGISTERED);

            // [Effect] Remove feed id from the registry
            let len_feed_ids: u32 = self.len_feed_ids.read();
            if len_feed_ids == 1 {
                self.remove_unique_feed_id();
            } else {
                self.remove_feed_id(len_feed_ids, feed_id_index.unwrap());
            }

            // [Interaction] Event emitted
            self.emit(RemovedFeedId { sender: get_caller_address(), feed_id: feed_id, })
        }

        /// Returns all the feed ids stored in the registry.
        fn get_all_feeds(self: @ContractState) -> Array<FeedId> {
            let mut all_feeds: Array<FeedId> = array![];

            let len_feed_ids: u32 = self.len_feed_ids.read();
            let mut i: u32 = 0;
            loop {
                if i >= len_feed_ids {
                    break;
                }
                let feed_id = self.feed_ids.read(i);
                all_feeds.append(feed_id);
            };
            all_feeds
        }

        /// Returns [true] if the [feed_id] provided is stored in the registry,
        /// else [false].
        fn feed_exists(self: @ContractState, feed_id: FeedId) -> bool {
            self.get_feed_id_index(feed_id).is_some()
        }
    }
    // ================== COMPONENTS IMPLEMENTATIONS ==================

    // Upgradeable impl
    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            // [Check] Only owner
            self.ownable.assert_only_owner();
            // [Effect] Upgrade contract
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    // ================== PRIVATE IMPLEMENTATIONS ==================

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        /// Returns the index of the provided feed id if it exists, else None.
        fn get_feed_id_index(self: @ContractState, feed_id: FeedId) -> Option<u32> {
            let mut feed_id_index: Option<u32> = Option::None(());

            let len_feed_ids: u32 = self.len_feed_ids.read();
            let mut i: u32 = 0;
            loop {
                if i >= len_feed_ids {
                    break;
                }
                let ith_feed_id = self.feed_ids.read(i);
                if feed_id == ith_feed_id {
                    feed_id_index = Option::Some(i);
                    break;
                }
            };

            feed_id_index
        }

        /// Remove the only feed id stored in the registry.
        /// Little optimization to avoid non-necessary lookups when the storage length
        /// is 1.
        fn remove_unique_feed_id(ref self: ContractState) {
            // [Effect] Remove feed id from registry
            self.feed_ids.write(0, 0);
            self.len_feed_ids.write(0);
        }

        /// Removes a feed id stored in the registry.
        fn remove_feed_id(ref self: ContractState, len_feed_ids: u32, feed_id_index: u32) {
            // [Check] Valid feed id index
            assert(feed_id_index < len_feed_ids, errors::INVALID_FEED_INDEX);

            // [Effect] Remove feed id from registry
            if (feed_id_index == len_feed_ids - 1) {
                self.feed_ids.write(feed_id_index, 0);
                self.len_feed_ids.write(len_feed_ids - 1);
            } else {
                let last_feed_id = self.feed_ids.read(len_feed_ids - 1);
                self.feed_ids.write(feed_id_index, last_feed_id);
                self.len_feed_ids.write(len_feed_ids - 1);
            }
        }
    }
}
