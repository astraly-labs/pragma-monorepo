use pragma_dispatcher::dispatcher::interface::{
    IPragmaDispatcherDispatcher, IPragmaDispatcherDispatcherTrait
};
use pragma_dispatcher::routers::asset_class::interface::IAssetClassRouterDispatcher;
use pragma_feed_types::{AssetClassId, AssetClass};
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,};
use starknet::{ContractAddress, contract_address_const};

/// Returns a mock owner address.
fn owner() -> ContractAddress {
    contract_address_const::<'owner'>()
}

/// Deploys the PragmaDispatcher contract and returns:
///     * the deployed contract address
///     * the dispatcher interface
fn deploy_pragma_dispatcher() -> (ContractAddress, IPragmaDispatcherDispatcher) {
    let contract = declare("PragmaDispatcher").unwrap().contract_class();
    let fake_registry_address = contract_address_const::<'fake_registry'>();
    let fake_mailbox_address = contract_address_const::<'fake_mailbox'>();
    let (contract_address, _) = contract
        .deploy(@array![owner().into(), fake_registry_address.into(), fake_mailbox_address.into()])
        .unwrap();
    let dispatcher = IPragmaDispatcherDispatcher { contract_address };
    start_cheat_caller_address(contract_address, owner());
    (contract_address, dispatcher)
}

/// Deploys an AssetClassRouter contract with the given asset_class_id.
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

#[test]
fn test_get_pragma_feed_registry_address() {
    let fake_registry_address = contract_address_const::<'fake_registry'>();
    let (_, dispatcher) = deploy_pragma_dispatcher();

    let registry_address = dispatcher.get_pragma_feed_registry_address();
    assert!(
        registry_address == fake_registry_address,
        "Should return the correct Pragma Feed Registry address"
    );
}

#[test]
fn test_get_hyperlane_mailbox_address() {
    let fake_mailbox_address = contract_address_const::<'fake_mailbox'>();
    let (_, dispatcher) = deploy_pragma_dispatcher();

    let mailbox_address = dispatcher.get_hyperlane_mailbox_address();
    assert!(
        mailbox_address == fake_mailbox_address,
        "Should return the correct Hyperlane Mailbox address"
    );
}

#[test]
fn test_register_and_get_asset_class_router() {
    let asset_class_id: AssetClassId = AssetClass::Crypto.into();
    let (_, dispatcher) = deploy_pragma_dispatcher();
    let (router_address, _) = deploy_asset_class_router(asset_class_id);

    // Register the asset class router
    dispatcher.register_asset_class_router(asset_class_id, router_address);

    // Get the registered router address
    let returned_router_address = dispatcher.get_asset_class_router(asset_class_id);
    assert!(
        returned_router_address == router_address,
        "Router address should match the registered address"
    );
}

#[test]
#[should_panic]
fn test_register_asset_class_router_invalid_asset_class_id() {
    let invalid_asset_class_id: AssetClassId = 9999;
    let (_, dispatcher) = deploy_pragma_dispatcher();
    let (router_address, _) = deploy_asset_class_router(invalid_asset_class_id);

    // Attempt to register a router with an invalid asset class ID
    dispatcher.register_asset_class_router(invalid_asset_class_id, router_address);
}

#[test]
#[should_panic]
fn test_register_asset_class_router_zero_address() {
    let asset_class_id: AssetClassId = AssetClass::Crypto.into();
    let (_, dispatcher) = deploy_pragma_dispatcher();
    let zero_address = contract_address_const::<0>();

    // Attempt to register a router with zero address
    dispatcher.register_asset_class_router(asset_class_id, zero_address);
}

#[test]
#[should_panic]
fn test_register_asset_class_router_mismatched_asset_class_id() {
    let asset_class_id: AssetClassId = AssetClass::Crypto.into();
    let (_, dispatcher) = deploy_pragma_dispatcher();
    let (router_address, _) = deploy_asset_class_router(1);

    // Attempt to register a router with mismatched asset class ID
    dispatcher.register_asset_class_router(asset_class_id, router_address);
}

#[test]
#[should_panic]
fn test_get_asset_class_router_not_registered() {
    let asset_class_id: AssetClassId = AssetClass::Crypto.into();
    let (_, dispatcher) = deploy_pragma_dispatcher();

    // Attempt to get router address without registering any router
    dispatcher.get_asset_class_router(asset_class_id);
}
