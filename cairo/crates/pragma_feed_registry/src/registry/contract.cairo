#[starknet::contract]
mod PragmaDispatcher {
    use starknet::ClassHash;
    use starknet::ContractAddress;
    use starknet::storage::Map;
    use alexandria_bytes::{Bytes, BytesTrait, BytesStore};

    use alexandria_storage::list::{List, ListTrait};
    use starknet::storage_access::{
        Store, StorageBaseAddress, storage_address_from_base,
        storage_address_from_base_and_offset, storage_base_address_from_felt252
    };
    use pragma_feed_types::types::feed::FeedIdTryIntoFeed;
    use starknet::storage_access;

    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_upgrades::{UpgradeableComponent, interface::IUpgradeable};

    use pragma_feed_types::types::{AssetClass, AssetClassId, FeedType, FeedTypeId, FeedId};
    use starknet::{SyscallResult, SyscallResultTrait};

    use crate::registry::interface::IPragmaRegistry;

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
        feed_ids_len: u32,
        feed_ids : LegacyMap<u32, FeedId>
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
        fn add_feed_id(ref self: ContractState, feed_id: ByteArray) {
            let length = self.feed_ids_len.read();
            self.feed_ids.write(length,feed_id.into()); 
            self.feed_ids_len.write(length +1);
        }

        fn get_all_feeds(self: @ContractState) -> Span<FeedId> {
            let mut cur_idx =0;
            let length = self.feed_ids_len.read();
            let mut arr = array![];
            loop {
                if (cur_idx >= length){
                    break;
                }
                arr.append(self.feed_ids.read(cur_idx));
                cur_idx +=1;
            };
           arr.span()
        }
    }
}
