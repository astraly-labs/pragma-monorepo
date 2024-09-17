use alexandria_bytes::Bytes;
use core::num::traits::Zero;
use pragma_dispatcher::routers::asset_class::contract::AssetClassRouter;
use pragma_dispatcher::routers::asset_class::interface::{
    IAssetClassRouterDispatcher, IAssetClassRouterDispatcherTrait
};
use pragma_dispatcher::routers::feed_types::interface::{
    IFeedTypeRouterDispatcher, IFeedTypeRouterDispatcherTrait
};
use pragma_feed_types::feed_type::{UniqueVariant};
use pragma_feed_types::{AssetClassId, AssetClass, FeedType, FeedTypeTrait, FeedTypeId, Feed};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait
};
use starknet::{ContractAddress, contract_address_const};

/// Returns the mock owner address.
fn owner() -> ContractAddress {
    contract_address_const::<'owner'>()
}

/// Deploys the AssetClassRouter contract and returns:
///     * the deployed contract address
///     * the router dispatcher
fn deploy_asset_class_router(
    asset_class_id: AssetClassId
) -> (ContractAddress, IAssetClassRouterDispatcher) {
    let contract = declare("AssetClassRouter").unwrap().contract_class();
    let (contract_address, _) = contract
        .deploy(@array![owner().into(), asset_class_id.into()])
        .unwrap();
    let dispatcher = IAssetClassRouterDispatcher { contract_address };
    start_cheat_caller_address(contract_address, owner());
    (contract_address, dispatcher)
}

/// Deploys a FeedTypeUniqueRouter contract with the given feed_type_id.
/// [get_data] is not tested so we don't care about mocking the inner calls.
fn deploy_feed_type_unique_router(
    feed_type_id: FeedTypeId
) -> (ContractAddress, IFeedTypeRouterDispatcher) {
    let fake_contract = contract_address_const::<'fake'>();
    let contract = declare("FeedTypeUniqueRouter").unwrap().contract_class();
    let (contract_address, _) = contract
        .deploy(@array![fake_contract.into(), fake_contract.into(), feed_type_id.into()])
        .unwrap();
    let dispatcher = IFeedTypeRouterDispatcher { contract_address };
    (contract_address, dispatcher)
}

#[test]
fn test_get_asset_class_id() {
    let asset_class_id: AssetClassId = AssetClass::Crypto.into();
    let (_, router) = deploy_asset_class_router(asset_class_id);

    let returned_asset_class_id = router.get_asset_class_id();

    assert!(
        returned_asset_class_id == asset_class_id,
        "Asset class ID should match the initialized value"
    );
}

#[test]
fn test_register_feed_type_router() {
    let asset_class_id: AssetClassId = AssetClass::Crypto.into();

    let feed_type = FeedType::Unique(UniqueVariant::SpotMedian);
    let feed_type_id: FeedTypeId = feed_type.id();

    let (router_address, router) = deploy_asset_class_router(asset_class_id);
    let (mock_router_address, _) = deploy_feed_type_unique_router(feed_type_id);

    // Create an event spy
    let mut spy = spy_events();

    // Register the feed type router
    router.register_feed_type_router(feed_type_id, mock_router_address);

    // Verify that the router was registered
    let returned_router_address = router.get_feed_type_router(feed_type_id);
    assert!(
        returned_router_address == mock_router_address,
        "Router address should match the registered address"
    );

    // Verify that the event was emitted
    spy
        .assert_emitted(
            @array![
                (
                    router_address,
                    AssetClassRouter::Event::FeedTypeRouterAdded(
                        AssetClassRouter::FeedTypeRouterAdded {
                            sender: owner(),
                            feed_type_id: feed_type_id,
                            router_address: mock_router_address,
                        }
                    )
                )
            ]
        );
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_register_feed_type_router_not_owner() {
    let asset_class_id: AssetClassId = AssetClass::Crypto.into();

    let feed_type = FeedType::Unique(UniqueVariant::SpotMedian);
    let feed_type_id: FeedTypeId = feed_type.id();

    let (router_address, router) = deploy_asset_class_router(asset_class_id);
    let (mock_router_address, _) = deploy_feed_type_unique_router(feed_type_id);

    // Stop cheat caller address to simulate non-owner
    stop_cheat_caller_address(router_address);
    let non_owner: ContractAddress = contract_address_const::<'non_owner'>();
    start_cheat_caller_address(router_address, non_owner);

    // Attempt to register feed type router as non-owner, should panic
    router.register_feed_type_router(feed_type_id, mock_router_address);
}

#[test]
#[should_panic(expected: 'Bad router for feed type id')]
fn test_register_feed_type_router_mismatched_feed_type_id() {
    let asset_class_id: AssetClassId = AssetClass::Crypto.into();

    let feed_type = FeedType::Unique(UniqueVariant::SpotMedian);
    let other_feed_type = FeedType::Unique(UniqueVariant::SpotMean);

    let (_, router) = deploy_asset_class_router(asset_class_id);
    // Deploy the mock feed type router with a different feed_type_id
    let (mock_router_address, _) = deploy_feed_type_unique_router(other_feed_type.id());

    // Attempt to register feed type router with mismatched feed_type_id
    router.register_feed_type_router(feed_type.id(), mock_router_address);
}

#[test]
#[should_panic(expected: 'No router registered')]
fn test_get_feed_type_router_not_registered() {
    let asset_class_id: AssetClassId = AssetClass::Crypto.into();

    let feed_type = FeedType::Unique(UniqueVariant::SpotMedian);
    let feed_type_id: FeedTypeId = feed_type.id();

    let (_, router) = deploy_asset_class_router(asset_class_id);

    // Attempt to get router address without registering any router
    router.get_feed_type_router(feed_type_id);
}

#[test]
#[should_panic(expected: 'Feed type router not found')]
fn test_get_feed_update_no_router_registered() {
    let asset_class_id: AssetClassId = AssetClass::Crypto.into();
    let feed_type = FeedType::Unique(UniqueVariant::SpotMedian);

    let (_, router) = deploy_asset_class_router(asset_class_id);

    // Create a feed with the feed_type
    let feed = Feed { asset_class: AssetClass::Crypto, feed_type: feed_type, pair_id: 'BTC/USD' };

    // Attempt to get feed update without registering a router, should panic
    router.get_feed_update(feed);
}

#[test]
#[should_panic(expected: 'Registered router cannot be 0')]
fn test_register_feed_type_router_zero_address() {
    let asset_class_id: AssetClassId = AssetClass::Crypto.into();

    let feed_type = FeedType::Unique(UniqueVariant::SpotMedian);
    let feed_type_id: FeedTypeId = feed_type.id();

    let (_, router) = deploy_asset_class_router(asset_class_id);

    // Attempt to register a router with zero address
    let zero_address = contract_address_const::<0>();
    router.register_feed_type_router(feed_type_id, zero_address);
}

#[test]
#[should_panic]
fn test_constructor_invalid_asset_class_id() {
    let invalid_asset_class_id: AssetClassId = 9999;
    deploy_asset_class_router(invalid_asset_class_id);
}

#[test]
#[should_panic]
fn test_constructor_owner_is_zero() {
    let asset_class_id: AssetClassId = AssetClass::Crypto.into();
    let contract = declare("AssetClassRouter").unwrap().contract_class();
    let zero_address = contract_address_const::<0>();
    contract.deploy(@array![zero_address.into(), asset_class_id.into()]).unwrap();
}
