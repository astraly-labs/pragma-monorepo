#[starknet::contract]
mod PragmaDispatcher {
    use core::num::traits::Zero;
    use crate::dispatcher::interface::IPragmaDispatcher;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_upgrades::{UpgradeableComponent, interface::IUpgradeable};
    use pragma_feed_types::{FeedId};
    use starknet::ClassHash;
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

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
        // Pragma Oracle contract
        pragma_oracle_address: ContractAddress,
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
        pragma_feed_registry_address: ContractAddress,
        hyperlane_mailbox_address: ContractAddress,
    ) {
        self
            .initializer(
                owner,
                pragma_oracle_address,
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

        /// Returns the list of supported data feeds.
        fn supported_data_feeds(self: @ContractState) -> Span<FeedId> {
            array![].span()
        }

        /// Dispatch a list of feed ids.
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

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(
            ref self: ContractState,
            owner: ContractAddress,
            pragma_oracle_address: ContractAddress,
            pragma_feed_registry_address: ContractAddress,
            hyperlane_mailbox_address: ContractAddress,
        ) {
            // [Check]
            assert(!owner.is_zero(), 'Owner cannot be 0');

            // [Effect]
            self.ownable.initializer(owner);
            self.pragma_oracle_address.write(pragma_oracle_address);
            self.pragma_feed_registry_address.write(pragma_feed_registry_address);
            self.hyperlane_mailbox_address.write(hyperlane_mailbox_address);
        }
    }
}
