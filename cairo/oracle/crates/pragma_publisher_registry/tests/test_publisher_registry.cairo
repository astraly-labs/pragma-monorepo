use pragma_publisher_registry::interface::{
    IPublisherRegistryABIDispatcher, IPublisherRegistryABIDispatcherTrait
};
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address};
use starknet::{ContractAddress, contract_address_const};

/// Returns the mock owner
fn owner() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}


fn publisher_address() -> ContractAddress {
    contract_address_const::<'PUBLISHER_1'>()
}

fn new_publisher_address() -> ContractAddress {
    contract_address_const::<'PUBLISHER_2'>()
}


pub fn deploy_publisher_registry() -> IPublisherRegistryABIDispatcher {
    // Declare the contract
    let contract = declare("PublisherRegistry").unwrap().contract_class();

    // Set up the constructor calldata
    let constructor_calldata = array![owner().into()];

    // Deploy the contract
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();

    // Create the dispatcher
    let dispatcher = IPublisherRegistryABIDispatcher { contract_address };

    // Start pranking as the admin
    start_cheat_caller_address(contract_address, owner());

    // Add publisher
    dispatcher.add_publisher('PUBLISHER 1', publisher_address());

    // Add sources for the publisher
    dispatcher.add_source_for_publisher('PUBLISHER 1', 1);
    dispatcher.add_source_for_publisher('PUBLISHER 1', 2);

    // Return the contract address and dispatcher
    dispatcher
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_register_non_admin_fail() {
    let publisher_registry = deploy_publisher_registry();

    let joe = contract_address_const::<'JOE'>();
    start_cheat_caller_address(publisher_registry.contract_address, joe);

    let test_add = contract_address_const::<0x1111111>();
    publisher_registry.add_publisher('PUBLISHER 1', test_add);
}

#[test]
fn test_add_publisher() {
    let publisher_registry = deploy_publisher_registry();
    let test_add = contract_address_const::<0x111222>();
    start_cheat_caller_address(publisher_registry.contract_address, owner());
    publisher_registry.add_publisher('PUBLISHER 2', test_add);
    assert(
        publisher_registry.get_publisher_address('PUBLISHER 2') == test_add,
        'wrong publisher address'
    );
}

#[test]
fn test_update_publisher_address() {
    let publisher_registry = deploy_publisher_registry();
    let test_new_address = contract_address_const::<'NEW_PUBLISHER_ADDRESS'>();

    start_cheat_caller_address(publisher_registry.contract_address, publisher_address());

    publisher_registry.update_publisher_address('PUBLISHER 1', test_new_address);

    assert(
        publisher_registry.get_publisher_address('PUBLISHER 1') == test_new_address,
        'wrong publisher address'
    );
}

#[test]
#[should_panic(expected: ('Caller is not the publisher',))]
fn test_update_publisher_should_fail_if_not_publisher() {
    let publisher_registry = deploy_publisher_registry();
    let test_add = contract_address_const::<'NEW_PUBLISHER_ADDRESS'>();

    let joe = contract_address_const::<'JOE'>();
    start_cheat_caller_address(publisher_registry.contract_address, joe);

    publisher_registry.update_publisher_address('PUBLISHER 1', test_add);
}

#[test]
#[should_panic(expected: ('Source already registered',))]
fn test_add_source_should_fail_if_source_already_exists() {
    let publisher_registry = deploy_publisher_registry();
    start_cheat_caller_address(publisher_registry.contract_address, owner());
    publisher_registry.add_source_for_publisher('PUBLISHER 1', 1);
}


#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_add_source_should_fail_if_not_admin() {
    let publisher_registry = deploy_publisher_registry();
    let joe = contract_address_const::<'JOE'>();
    start_cheat_caller_address(publisher_registry.contract_address, joe);
    publisher_registry.add_source_for_publisher('PUBLISHER 1', 3);
}

#[test]
fn test_add_source() {
    let publisher_registry = deploy_publisher_registry();
    start_cheat_caller_address(publisher_registry.contract_address, owner());
    publisher_registry.add_source_for_publisher('PUBLISHER 1', 3);
    assert(publisher_registry.can_publish_source('PUBLISHER 1', 3), 'should publish source');
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_remove_source_should_fail_if_not_admin() {
    let publisher_registry = deploy_publisher_registry();
    let joe = contract_address_const::<'JOE'>();
    start_cheat_caller_address(publisher_registry.contract_address, joe);
    publisher_registry.remove_source_for_publisher('PUBLISHER 1', 1);
}

#[test]
#[should_panic(expected: ('Source not found for publisher',))]
fn test_remove_source_should_fail_if_source_does_not_exist() {
    let publisher_registry = deploy_publisher_registry();
    start_cheat_caller_address(publisher_registry.contract_address, owner());
    publisher_registry.remove_source_for_publisher('PUBLISHER 1', 3);
}


#[test]
fn test_remove_source() {
    let publisher_registry = deploy_publisher_registry();
    start_cheat_caller_address(publisher_registry.contract_address, owner());
    publisher_registry.remove_source_for_publisher('PUBLISHER 1', 2);
    assert(!publisher_registry.can_publish_source('PUBLISHER 1', 2), 'should not publish source');
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_remove_publisher_should_fail_if_not_admin() {
    let publisher_registry = deploy_publisher_registry();
    let joe = contract_address_const::<'JOE'>();
    start_cheat_caller_address(publisher_registry.contract_address, joe);
    publisher_registry.remove_publisher('PUBLISHER 1');
}

#[test]
fn test_remove_publisher() {
    let publisher_registry = deploy_publisher_registry();
    start_cheat_caller_address(publisher_registry.contract_address, owner());
    publisher_registry.remove_publisher('PUBLISHER 1');
    assert(
        publisher_registry.get_publisher_address(1) == 0.try_into().unwrap(),
        'should not be publisher'
    );
}

#[test]
#[should_panic(expected: ('Publisher not found',))]
fn test_remove_publisher_should_fail_if_publisher_does_not_exist() {
    let publisher_registry = deploy_publisher_registry();
    start_cheat_caller_address(publisher_registry.contract_address, owner());
    publisher_registry.remove_publisher(2);
}


#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_add_publisher_should_fail_if_not_admin() {
    let publisher_registry = deploy_publisher_registry();
    let joe = contract_address_const::<'JOE'>();
    start_cheat_caller_address(publisher_registry.contract_address, joe);
    publisher_registry.add_publisher(2, contract_address_const::<0x12345>());
}

#[test]
#[should_panic(expected: ('Cannot set address to zero',))]
fn test_add_publisher_should_fail_if_null_address() {
    let publisher_registry = deploy_publisher_registry();
    start_cheat_caller_address(publisher_registry.contract_address, owner());
    publisher_registry.add_publisher(2, 0.try_into().unwrap());
}

#[test]
#[should_panic(expected: ('Pbsher name already registered',))]
fn test_add_publisher_should_fail_if_publisher_already_exists() {
    let publisher_registry = deploy_publisher_registry();
    start_cheat_caller_address(publisher_registry.contract_address, owner());
    publisher_registry.add_publisher('PUBLISHER 1', owner());
}


#[test]
fn test_remove_source_for_all_publishers() {
    let publisher_registry = deploy_publisher_registry();
    publisher_registry.add_publisher('PUBLISHER 2', new_publisher_address());

    publisher_registry.add_source_for_publisher('PUBLISHER 2', 1);
    // Add source 2 for publisher 1
    publisher_registry.add_source_for_publisher('PUBLISHER 2', 2);
    //Add a new source to both publishers
    publisher_registry.add_source_for_publisher('PUBLISHER 2', 3);
    publisher_registry.add_source_for_publisher('PUBLISHER 1', 3);
    let sources_1 = publisher_registry.get_publisher_sources('PUBLISHER 1');
    let sources_2 = publisher_registry.get_publisher_sources('PUBLISHER 2');
    assert(sources_1.len() == 3, 'Source not added');
    assert(sources_2.len() == 3, 'Source not added');
    publisher_registry.remove_source_for_all_publishers(3);
    let sources_1 = publisher_registry.get_publisher_sources('PUBLISHER 1');
    let sources_2 = publisher_registry.get_publisher_sources('PUBLISHER 2');
    assert(sources_1.len() == 2, 'Source not deleted');
    assert(sources_2.len() == 2, 'Source not deleted');
}

#[test]
#[should_panic(expected: ('Address already registered',))]
fn test_add_pubisher_should_fail_if_already_registered() {
    let publisher_registry = deploy_publisher_registry();
    start_cheat_caller_address(publisher_registry.contract_address, owner());
    publisher_registry.add_publisher('PUBLISHER 2', publisher_address());
}


#[test]
#[should_panic(expected: ('Address already registered',))]
fn test_update_pubisher_should_fail_if_already_registered() {
    let publisher_registry = deploy_publisher_registry();
    start_cheat_caller_address(publisher_registry.contract_address, owner());
    publisher_registry.add_publisher('PUBLISHER 2', new_publisher_address());
    publisher_registry.update_publisher_address('PUBLISHER 2', publisher_address());
}
