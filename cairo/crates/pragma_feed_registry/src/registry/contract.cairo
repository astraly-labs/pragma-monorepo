#[starknet::contract]
mod PragmaFeedRegistry {
    use crate::registry::errors;

    use crate::registry::interface::IPragmaRegistry;

    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_upgrades::{UpgradeableComponent, interface::IUpgradeable};

    use pragma_feed_types::{FeedId, Feed, FeedTrait};
    use starknet::storage::StoragePathEntry;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, Map};
    use starknet::{ClassHash, ContractAddress, get_caller_address};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        len_feed_ids: u32,
        feed_ids: Map<u32, FeedId> // All supported feed ids
    }

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

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    #[abi(embed_v0)]
    impl PragmaRegistry of IPragmaRegistry<ContractState> {
        fn add_feed(ref self: ContractState, feed_id: FeedId) {
            self.ownable.assert_only_owner();

            let new_feed_option: Option<Feed> = FeedTrait::from_id(feed_id);
            assert(new_feed_option.is_some(), errors::INVALID_FEED_FORMAT);

            let len_feed_ids = self.len_feed_ids.read();
            for i in 0
                ..len_feed_ids {
                    let ith_feed_id = self.feed_ids.entry(i).read();
                    assert(ith_feed_id != feed_id, errors::FEED_ALREADY_REGISTERED);
                };

            self.feed_ids.entry(len_feed_ids).write(feed_id);
            self.len_feed_ids.write(len_feed_ids + 1);
            self.emit(NewFeedId { sender: get_caller_address(), feed_id: feed_id, })
        }

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

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
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

        fn _remove_unique_feed_id(ref self: ContractState) {
            self.feed_ids.entry(0).write(0);
            self.len_feed_ids.write(0);
        }

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
