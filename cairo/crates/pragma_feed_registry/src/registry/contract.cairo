#[starknet::contract]
mod PragmaFeedRegistry {
    use crate::registry::interface::IPragmaRegistry;

    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_upgrades::{UpgradeableComponent, interface::IUpgradeable};

    use pragma_feed_types::{FeedId, Feed, feed::{FeedIdTryIntoFeed}};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, Vec, VecTrait, MutableVecTrait
    };
    use starknet::{ClassHash, ContractAddress};

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
        feed_ids: Vec<FeedId> // All supported feed ids
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event
        // TODO(akhercha): New feed id added event
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
        fn add_feed_id(ref self: ContractState, feed_id: FeedId) {
            self.ownable.assert_only_owner();

            let new_feed_option: Option<Feed> = feed_id.clone().try_into();
            // TODO(akhercha): errors module
            assert(new_feed_option.is_some(), 'INVALID FEED ID FORMAT');

            for i in 0
                ..self
                    .feed_ids
                    .len() {
                        let ith_feed_id = self.feed_ids.at(i).read();
                        // TODO(akhercha): errors module
                        assert(ith_feed_id != feed_id, 'FEED ID ALREADY REGISTERED');
                    };

            self.feed_ids.append().write(feed_id);
        }

        fn get_all_feeds(self: @ContractState) -> Array<FeedId> {
            let mut all_feeds: Array<FeedId> = array![];
            for i in 0
                ..self
                    .feed_ids
                    .len() {
                        let feed_id = self.feed_ids.at(i).read();
                        all_feeds.append(feed_id);
                    };
            all_feeds
        }

        fn feed_exists(self: @ContractState, feed_id: FeedId) -> bool {
            let mut found = false;
            for i in 0
                ..self
                    .feed_ids
                    .len() {
                        let ith_feed_id = self.feed_ids.at(i).read();
                        if feed_id == ith_feed_id {
                            found = true;
                            break;
                        }
                    };
            found
        }
    }
}
