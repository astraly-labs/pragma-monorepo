#[starknet::contract]
mod PragmaDispatcher {
    use starknet::ClassHash;
    use starknet::ContractAddress;
    use starknet::storage::Map;
    
    use alexandria_storage::list::{List};

    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_upgrades::{UpgradeableComponent, interface::IUpgradeable};

    use pragma_feeds::types::{AssetClass, AssetClassId, FeedType, FeedTypeId, FeedId};
    
    use super::interface::IPragmaRegistry;

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
        
        feed_ids: List<FeedId>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event
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
        fn add_feed_id(ref self: TContractState, feed_id: FeedId) {
            let feed_ids = self.feed_ids.read();
            if feed_ids.exists(feed_id) {
                panic_with_felt252!('FEED ID ALREADY EXISTS');
            }
            feed_ids.append(feed_id);
        }

        fn get_all_feeds(self: @TContractState) -> Span<FeedId> {
            self.feed_ids.read().span()
        }
    }
}
