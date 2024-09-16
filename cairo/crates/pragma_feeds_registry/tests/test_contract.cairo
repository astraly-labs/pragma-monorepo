use pragma_feed_types::FeedId;
use pragma_feeds_registry::contract::PragmaFeedsRegistry;
use pragma_feeds_registry::{IPragmaFeedsRegistryDispatcher, IPragmaFeedsRegistryDispatcherTrait};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, spy_events, SpyOn,
    EventAssertions
};
use starknet::{ContractAddress, contract_address_const};

/// Returns the mock owner
fn owner() -> ContractAddress {
    contract_address_const::<'new_owner'>()
}

/// Deploys the Pragma Feeds Registry contract and returns:
///     * the deployed contract address
///     * the registry dispatcher
fn deploy_pragma_registry() -> (ContractAddress, IPragmaFeedsRegistryDispatcher) {
    let contract = declare("PragmaFeedsRegistry").unwrap();
    let (contract_address, _) = contract.deploy(@array![owner().into()]).unwrap();
    let dispatcher = IPragmaFeedsRegistryDispatcher { contract_address };
    start_prank(CheatTarget::One(contract_address), owner());
    (contract_address, dispatcher)
}

#[test]
fn test_add_feed() {
    let (registry_address, registry) = deploy_pragma_registry();
    let mut spy = spy_events(SpyOn::One(registry_address));

    let feed_id: FeedId = 0x456;

    registry.add_feed(feed_id);

    assert!(registry.feed_exists(feed_id), "Feed should exist");
    spy
        .assert_emitted(
            @array![
                (
                    registry_address,
                    PragmaFeedsRegistry::Event::NewFeedId(
                        PragmaFeedsRegistry::NewFeedId { sender: owner(), feed_id: 0x456, }
                    )
                )
            ]
        );
}

#[test]
#[should_panic(expected: ('Feed ID already registed',))]
fn test_add_duplicate_feed() {
    let (_, registry) = deploy_pragma_registry();

    let feed_id: FeedId = 0x456;
    registry.add_feed(feed_id);
    registry.add_feed(feed_id);
}

#[test]
fn test_remove_feed() {
    let (registry_address, registry) = deploy_pragma_registry();
    let mut spy = spy_events(SpyOn::One(registry_address));

    let feed_id: FeedId = 0x456;
    registry.add_feed(feed_id);
    registry.remove_feed(feed_id);

    assert!(!registry.feed_exists(feed_id), "Feed should not exist");
    spy
        .assert_emitted(
            @array![
                (
                    registry_address,
                    PragmaFeedsRegistry::Event::RemovedFeedId(
                        PragmaFeedsRegistry::RemovedFeedId { sender: owner(), feed_id: 0x456, }
                    )
                )
            ]
        );
}

#[test]
fn test_get_all_feeds() {
    let (_, registry) = deploy_pragma_registry();

    let expected_feeds: Array<felt252> = array![0x123, 0x456, 0x789];

    let mut feeds_to_add = expected_feeds.span();
    loop {
        match feeds_to_add.pop_front() {
            Option::Some(v) => registry.add_feed(*v),
            Option::None(()) => { break; },
        }
    };

    let out_feeds = registry.get_all_feeds();
    assert_eq!(out_feeds, expected_feeds, "Should return all added feeds");
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_add_feed_not_owner() {
    let (registry_address, registry) = deploy_pragma_registry();

    stop_prank(CheatTarget::One(registry_address));
    let non_owner = 0x789.try_into().unwrap();
    start_prank(CheatTarget::One(registry_address), non_owner);

    registry.add_feed(0x123);
}
