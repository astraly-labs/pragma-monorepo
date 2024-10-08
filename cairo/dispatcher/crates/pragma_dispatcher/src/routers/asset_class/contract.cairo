#[starknet::contract]
pub mod AssetClassRouter {
    use core::num::traits::Zero;
    use core::panic_with_felt252;
    use openzeppelin::access::ownable::OwnableComponent;
    use pragma_dispatcher::routers::asset_class::{errors, interface::{IAssetClassRouter}};
    use pragma_dispatcher::routers::{IFeedTypeRouterDispatcher, IFeedTypeRouterDispatcherTrait};
    use pragma_feed_types::{AssetClass, AssetClassId, Feed, FeedType, FeedTypeTrait, FeedTypeId};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map
    };
    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    // ================== COMPONENTS ==================

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // ================== STORAGE ==================

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        asset_class: AssetClass,
        feed_type_routers: Map<FeedType, IFeedTypeRouterDispatcher>,
    }

    // ================== EVENTS ==================

    #[derive(starknet::Event, Drop)]
    pub struct AssetClassRouterDeployed {
        pub sender: ContractAddress,
        pub asset_class_id: AssetClassId,
        pub router_address: ContractAddress,
    }

    #[derive(starknet::Event, Drop)]
    pub struct FeedTypeRouterAdded {
        pub sender: ContractAddress,
        pub feed_type_id: FeedTypeId,
        pub router_address: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        AssetClassRouterDeployed: AssetClassRouterDeployed,
        FeedTypeRouterAdded: FeedTypeRouterAdded
    }

    // ================== CONSTRUCTOR ================================

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, asset_class_id: AssetClassId) {
        self.initializer(owner, asset_class_id);
    }

    // ================== PUBLIC ABI ==================

    #[abi(embed_v0)]
    impl AssetClassRouterImpl of IAssetClassRouter<ContractState> {
        /// Registers a new router for the provided feed type id.
        fn register_feed_type_router(
            ref self: ContractState, feed_type_id: FeedTypeId, router_address: ContractAddress
        ) {
            // [Check] Only owner
            self.ownable.assert_only_owner();
            // [Check] Router is not zero
            assert(!router_address.is_zero(), errors::REGISTERING_ROUTER_ZERO);
            // [Check] Valid feed type
            let feed_type: FeedType = match FeedTypeTrait::from_id(feed_type_id) {
                Result::Ok(f) => f,
                Result::Err(e) => panic_with_felt252(e.into())
            };
            // [Check] Matching feed type ids with the given router
            let router = IFeedTypeRouterDispatcher { contract_address: router_address };
            assert(router.get_feed_type_id() == feed_type_id, errors::MISMATCH_FEED_TYPE_ID);

            // [Effect] Update the router for the given feed type
            self.feed_type_routers.entry(feed_type).write(router);

            // [Interaction] Storage updated event
            self
                .emit(
                    FeedTypeRouterAdded {
                        sender: get_caller_address(),
                        feed_type_id: feed_type_id,
                        router_address: router_address,
                    }
                )
        }

        /// Returns the asset class id of the current router.
        fn get_asset_class_id(self: @ContractState) -> AssetClassId {
            self.asset_class.read().into()
        }

        /// Returns the router address registered for the Feed Type.
        fn get_feed_type_router(self: @ContractState, feed_type_id: FeedTypeId) -> ContractAddress {
            // [Check] Valid feed type
            let feed_type = match FeedTypeTrait::from_id(feed_type_id) {
                Result::Ok(f) => f,
                Result::Err(e) => panic_with_felt252(e.into())
            };
            // [Check] A router is registered for the asset class
            let router = self.feed_type_routers.entry(feed_type).read();
            assert(!router.is_zero(), errors::NO_ROUTER_REGISTERED);

            // [Interaction] Return the router address
            router.contract_address
        }

        /// For a given feed, calls the registered router [get_data] function and returns the data
        /// as bytes.
        fn get_feed_update(self: @ContractState, feed: Feed) -> alexandria_bytes::Bytes {
            // [Check] Feed id route exists
            let router: IFeedTypeRouterDispatcher = self
                .feed_type_routers
                .entry(feed.feed_type)
                .read();
            assert(!router.is_zero(), errors::FEED_TYPE_ROUTER_NOT_FOUND);

            // [Effect] Retrieve the feed update and return the data as Bytes
            router.get_data(feed)
        }
    }

    // ================== PRIVATE IMPLEMENTATIONS ==================

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Initializes the contract storage.
        /// Called only once by the constructor.
        fn initializer(
            ref self: ContractState, owner: ContractAddress, asset_class_id: AssetClassId
        ) {
            // [Check] Owner is valid
            assert(!owner.is_zero(), errors::OWNER_IS_ZERO);
            // [Check] Valid asset class id
            let asset_class: AssetClass = match asset_class_id.try_into() {
                Option::Some(a) => a,
                Option::None(()) => panic_with_felt252(errors::INVALID_ASSET_CLASS_ID)
            };

            // [Effect] Init components storages
            self.ownable.initializer(owner);
            self.asset_class.write(asset_class);

            // [Interaction] Emit new router deployed
            self
                .emit(
                    AssetClassRouterDeployed {
                        sender: get_caller_address(),
                        asset_class_id: asset_class_id,
                        router_address: get_contract_address(),
                    }
                )
        }
    }
}
