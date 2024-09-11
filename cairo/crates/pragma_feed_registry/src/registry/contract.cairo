#[starknet::contract]
mod PragmaFeedRegistry {
    use crate::registry::errors;
    use crate::registry::interface::IPragmaFeedRegistry;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_upgrades::{UpgradeableComponent, interface::IUpgradeable};
    use pragma_feed_types::{FeedId, FeedTrait};
    use starknet::storage::StoragePathEntry;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, Map};
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
        len_feed_ids: u32,
        feed_ids: Map<u32, FeedId> // All supported feed ids & thei
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
        self.ownable.initializer(owner);
    }

    // ================== PUBLIC ABI ==================

    #[abi(embed_v0)]
    impl PragmaFeedRegistry of IPragmaFeedRegistry<ContractState> {
        /// Adds a feed_id into the Registry.
        ///
        /// Panics if:
        ///     * the feed_id format is incorrect,
        ///     * the feed_id is already registered.
        fn add_feed(ref self: ContractState, feed_id: FeedId) {
            self.ownable.assert_only_owner();

            assert(FeedTrait::from_id(feed_id).is_some(), errors::INVALID_FEED_FORMAT);
            assert(self._get_feed_id_index(feed_id).is_none(), errors::FEED_ALREADY_REGISTERED);

            let len_feed_ids = self.len_feed_ids.read();
            self.feed_ids.entry(len_feed_ids).write(feed_id);
            self.len_feed_ids.write(len_feed_ids + 1);

            self.emit(NewFeedId { sender: get_caller_address(), feed_id: feed_id, })
        }

        /// Removes a feed_id from the Registry.
        ///
        /// Panics if the feed_id is not in the Registry.
        fn remove_feed(ref self: ContractState, feed_id: FeedId) {
            self.ownable.assert_only_owner();

            let len_feed_ids: u32 = self.len_feed_ids.read();
            if len_feed_ids == 1 {
                assert(self.feed_ids.entry(0).read() == feed_id, errors::FEED_NOT_REGISTERED);
                self._remove_unique_feed_id();
            } else {
                let feed_id_index: Option<u32> = self._get_feed_id_index(feed_id);
                assert(feed_id_index.is_some(), errors::FEED_NOT_REGISTERED);
                self._remove_feed_id(len_feed_ids, feed_id_index.unwrap());
            }

            self.emit(RemovedFeedId { sender: get_caller_address(), feed_id: feed_id, })
        }

        /// Returns all the feed ids stored in the registry.
        fn get_all_feeds(self: @ContractState) -> Array<FeedId> {
            let mut all_feeds: Array<FeedId> = array![];
            for i in 0
                ..self
                    .len_feed_ids
                    .read() {
                        let feed_id = self.feed_ids.entry(i).read();
                        all_feeds.append(feed_id);
                    };
            all_feeds
        }

        /// Returns [true] if the [feed_id] provided is stored in the registry,
        /// else [false].
        fn feed_exists(self: @ContractState, feed_id: FeedId) -> bool {
            let mut found = false;
            for i in 0
                ..self
                    .len_feed_ids
                    .read() {
                        let ith_feed_id = self.feed_ids.entry(i).read();
                        if feed_id == ith_feed_id {
                            found = true;
                            break;
                        }
                    };
            found
        }
    }
    // ================== COMPONENTS IMPLEMENTATIONS ==================

    // Upgradeable impl
    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    // ================== PRIVATE HELPER FUNCTIONS ==================

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        /// Returns the index of the provided feed id if it exists, else None.
        fn _get_feed_id_index(self: @ContractState, feed_id: FeedId) -> Option<u32> {
            let mut feed_id_index: Option<u32> = Option::None(());
            for i in 0
                ..self
                    .len_feed_ids
                    .read() {
                        let ith_feed_id = self.feed_ids.entry(i).read();
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
        fn _remove_unique_feed_id(ref self: ContractState) {
            self.feed_ids.entry(0).write(0);
            self.len_feed_ids.write(0);
        }

        /// Removes a feed id stored in the registry.
        fn _remove_feed_id(ref self: ContractState, len_feed_ids: u32, feed_id_index: u32) {
            if (feed_id_index == len_feed_ids - 1) {
                self.feed_ids.entry(feed_id_index).write(0);
                self.len_feed_ids.write(0);
            } else {
                let last_feed_id = self.feed_ids.entry(len_feed_ids - 1).read();
                self.feed_ids.entry(feed_id_index).write(last_feed_id);
                self.len_feed_ids.write(len_feed_ids - 1);
            }
        }
    }
}
