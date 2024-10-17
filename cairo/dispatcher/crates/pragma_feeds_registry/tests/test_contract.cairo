use pragma_feed_types::FeedId;
use pragma_feeds_registry::contract::PragmaFeedsRegistry;
use pragma_feeds_registry::{IPragmaFeedsRegistryDispatcher, IPragmaFeedsRegistryDispatcherTrait};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait
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
    let contract = declare("PragmaFeedsRegistry").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![owner().into()]).unwrap();
    let dispatcher = IPragmaFeedsRegistryDispatcher { contract_address };
    start_cheat_caller_address(contract_address, owner());
    (contract_address, dispatcher)
}

#[test]
fn test_add_feed() {
    let (registry_address, registry) = deploy_pragma_registry();
    let mut spy = spy_events();

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
fn test_add_feeds() {
    let (registry_address, registry) = deploy_pragma_registry();
    let mut spy = spy_events();

    let feed_ids: Array<FeedId> = array![0x123, 0x456, 0x789];

    registry.add_feeds(feed_ids.span());

    // Check if all feeds exist
    for feed_id in feed_ids
        .clone() {
            assert!(registry.feed_exists(feed_id), "Feed should exist");
        };

    // Check if the correct number of feeds were added
    let all_feeds = registry.get_all_feeds();
    assert!(all_feeds.len() == feed_ids.len(), "Number of feeds should match");

    // Check if events were emitted for each feed
    let mut expected_events = array![];
    for feed_id in feed_ids {
        expected_events
            .append(
                (
                    registry_address,
                    PragmaFeedsRegistry::Event::NewFeedId(
                        PragmaFeedsRegistry::NewFeedId { sender: owner(), feed_id }
                    )
                )
            );
    };
    spy.assert_emitted(@expected_events);
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
    let mut spy = spy_events();

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

    for feed in expected_feeds.clone() {
        registry.add_feed(feed);
    };

    let out_feeds = registry.get_all_feeds();
    assert!(out_feeds == expected_feeds, "Should return all added feeds");
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_add_feed_not_owner() {
    let (registry_address, registry) = deploy_pragma_registry();

    stop_cheat_caller_address(registry_address);
    let non_owner = 0x789.try_into().unwrap();
    start_cheat_caller_address(registry_address, non_owner);

    registry.add_feed(0x123);
}
