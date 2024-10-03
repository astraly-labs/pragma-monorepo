use pragma_entry::structures::{
    USD_CURRENCY_ID, Currency, Pair, SpotEntry, FutureEntry, PragmaPricesResponse, BaseEntry,
    Checkpoint, SimpleDataType, PossibleEntries, AggregationMode, DataType
};
use pragma_oracle::interface::{IOracleABIDispatcher, IOracleABIDispatcherTrait};
use pragma_publisher_registry::interface::{
    IPublisherRegistryABIDispatcher, IPublisherRegistryABIDispatcherTrait
};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    start_cheat_block_timestamp_global,
};
use starknet::{ContractAddress, contract_address_const};

fn owner() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}


fn publisher_address() -> ContractAddress {
    contract_address_const::<'PUBLISHER_1'>()
}

fn setup() -> (IPublisherRegistryABIDispatcher, IOracleABIDispatcher) {
    // Deploy PublisherRegistry
    let publisher_registry = deploy_publisher_registry();
    let now = 100000;
    start_cheat_block_timestamp_global(now);
    // Setup currencies
    let address = contract_address_const::<0>();
    let currencies = array![
        (111, 18_u32, false, address, address),
        (222, 18_u32, false, address, address),
        (USD_CURRENCY_ID, 6_u32, false, address, address),
        (333, 18_u32, false, address, address),
        ('hop', 10_u32, false, address, address),
    ];

    // Setup pairs
    let pairs = array![
        (1, 111, 222),
        (2, 111, USD_CURRENCY_ID),
        (3, 222, USD_CURRENCY_ID),
        (4, 111, 333),
        (5, 333, USD_CURRENCY_ID),
        (6, 'hop', USD_CURRENCY_ID),
    ];

    let formatted_currencies = build_currencies(currencies);
    let formatted_pairs = build_pairs(pairs);
    // Deploy Oracle
    let mut oracle_calldata = ArrayTrait::<felt252>::new();
    owner().serialize(ref oracle_calldata);
    publisher_registry.contract_address.serialize(ref oracle_calldata);
    formatted_currencies.serialize(ref oracle_calldata);
    formatted_pairs.serialize(ref oracle_calldata);
    let oracle = declare("Oracle").unwrap().contract_class();
    let (oracle_address, _) = oracle.deploy(@oracle_calldata).unwrap();

    // Publish data
    let oracle = IOracleABIDispatcher { contract_address: oracle_address };
    publish_spot_entries(oracle);
    publish_future_entries(oracle);

    (publisher_registry, oracle)
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
    dispatcher.add_publisher(1, publisher_address());

    // Add sources for the publisher
    dispatcher.add_source_for_publisher(1, 1);
    dispatcher.add_source_for_publisher(1, 2);

    // Return the contract address and dispatcher
    dispatcher
}


fn build_currencies(
    input: Array<(felt252, u32, bool, ContractAddress, ContractAddress)>
) -> Array<Currency> {
    let mut currencies: Array<Currency> = array![];
    for i in 0
        ..input
            .len() {
                let (id, decimals, is_abstract_currency, starknet_address, ethereum_address) =
                    *input[i];
                currencies
                    .append(
                        {
                            Currency {
                                id,
                                decimals,
                                is_abstract_currency,
                                starknet_address,
                                ethereum_address
                            }
                        }
                    );
            };
    currencies
}

fn build_pairs(input: Array<(felt252, felt252, felt252)>) -> Array<Pair> {
    let mut pairs: Array<Pair> = array![];
    for i in 0
        ..input
            .len() {
                let (id, quote_currency_id, base_currency_id) = *input[i];
                pairs.append(Pair { id, quote_currency_id, base_currency_id });
            };
    pairs
}


fn publish_spot_entries(oracle: IOracleABIDispatcher) {
    start_cheat_caller_address(oracle.contract_address, publisher_address());
    let now = 100000;
    let spot_entries: Array<(felt252, felt252, u128, u128)> = array![
        (2, 1, 2 * 1000000, 100),
        (2, 2, 3 * 1000000, 50),
        (3, 1, 8 * 1000000, 100),
        (4, 1, 8 * 1000000, 20),
        (4, 2, 3 * 1000000, 10),
        (5, 1, 5 * 1000000, 20),
        (6, 1, 2 * 1000000, 440),
    ];

    for i in 0
        ..spot_entries
            .len() {
                let (pair_id, source, price, volume) = *spot_entries[i];
                oracle
                    .publish_data(
                        PossibleEntries::Spot(
                            SpotEntry {
                                base: BaseEntry { timestamp: now, source: source, publisher: 1 },
                                pair_id: pair_id,
                                price: price,
                                volume: volume
                            }
                        )
                    );
            };
}

fn publish_future_entries(oracle: IOracleABIDispatcher) {
    start_cheat_caller_address(oracle.contract_address, publisher_address());
    let now = 100000;
    let expiration_timestamp = 11111110;
    let future_entries: Array<(felt252, felt252, u128, u128)> = array![
        (2, 1, 2 * 1000000, 40),
        (2, 2, 2 * 1000000, 30),
        (3, 1, 3 * 1000000, 1000),
        (4, 1, 4 * 1000000, 2321),
        (5, 1, 5 * 1000000, 231),
        (5, 2, 5 * 1000000, 232),
    ];
    for i in 0
        ..future_entries
            .len() {
                let (pair_id, source, price, volume) = *future_entries.at(i);
                oracle
                    .publish_data(
                        PossibleEntries::Future(
                            FutureEntry {
                                base: BaseEntry { timestamp: now, source: source, publisher: 1 },
                                pair_id: pair_id,
                                price: price,
                                volume: volume,
                                expiration_timestamp
                            }
                        )
                    );
            };
}

#[test]
fn test_get_decimals() {
    let (_, oracle) = setup();
    let decimals_1 = oracle.get_decimals(DataType::SpotEntry(1));
    assert(decimals_1 == 18_u32, 'wrong decimals value');
    let decimals_2 = oracle.get_decimals(DataType::SpotEntry(2));
    assert(decimals_2 == 6_u32, 'wrong decimals value');
    let decimals_4 = oracle.get_decimals(DataType::FutureEntry((1, 11111110)));
    assert(decimals_4 == 18_u32, 'wrong decimals value');
    let decimals_5 = oracle.get_decimals(DataType::FutureEntry((2, 11111110)));
    assert(decimals_5 == 6_u32, 'wrong decimals value');
}
#[test]
#[should_panic(expected: ('No pair recorded',))]
fn test_get_decimals_should_fail_if_not_found() {
    //Test should fail if the pair_id is not found
    let (_, oracle) = setup();
    oracle.get_decimals(DataType::SpotEntry(100));
}

#[test]
#[should_panic(expected: ('No pair recorded',))]
fn test_get_decimals_should_fail_if_not_found_2() {
    //Test should fail if the pair_id or the expiration timestamp is not related to a FutureEntry
    let (_, oracle) = setup();
    oracle.get_decimals(DataType::FutureEntry((100, 110100)));
}

#[test]
fn test_data_entry() {
    let (_, oracle) = setup();
    let entry = oracle.get_data_entry(DataType::SpotEntry(2), 1, 1);
    let (price, _, _) = data_treatment(entry);
    assert(price == (2000000), 'wrong price');
    let entry = oracle.get_data_entry(DataType::SpotEntry(2), 2, 1);
    let (price, _, _) = data_treatment(entry);
    assert(price == (3000000), 'wrong price');
    let entry = oracle.get_data_entry(DataType::SpotEntry(3), 1, 1);
    let (price, _, _) = data_treatment(entry);
    assert(price == (8000000), 'wrong price');
    let entry = oracle.get_data_entry(DataType::SpotEntry(4), 1, 1);
    let (price, _, _) = data_treatment(entry);
    assert(price == (8000000), 'wrong price');
    let entry = oracle.get_data_entry(DataType::SpotEntry(4), 2, 1);
    let (price, _, _) = data_treatment(entry);
    assert(price == (3000000), 'wrong price');
    let entry = oracle.get_data_entry(DataType::SpotEntry(5), 1, 1);
    let (price, _, _) = data_treatment(entry);
    assert(price == (5000000), 'wrong price');
    let entry = oracle.get_data_entry(DataType::FutureEntry((2, 11111110)), 1, 1);
    let (price, _, _) = data_treatment(entry);
    assert(price == (2000000), 'wrong price');
    let entry = oracle.get_data_entry(DataType::FutureEntry((2, 11111110)), 2, 1);
    let (price, _, _) = data_treatment(entry);
    assert(price == (2000000), 'wrong price');
    let entry = oracle.get_data_entry(DataType::FutureEntry((3, 11111110)), 1, 1);
    let (price, _, _) = data_treatment(entry);
    assert(price == (3000000), 'wrong price');
    let entry = oracle.get_data_entry(DataType::FutureEntry((4, 11111110)), 1, 1);
    let (price, _, _) = data_treatment(entry);
    assert(price == (4000000), 'wrong price');
    let entry = oracle.get_data_entry(DataType::FutureEntry((5, 11111110)), 1, 1);
    let (price, _, _) = data_treatment(entry);
    assert(price == (5000000), 'wrong price');
}

#[test]
#[should_panic(expected: ('No data entry found',))]
fn test_data_entry_should_fail_if_not_found() {
    //no panic because we want get_data_entry is called the first time data is published
    let (_, oracle) = setup();
    oracle.get_data_entry(DataType::SpotEntry(100), 1, 1);
}

#[test]
#[should_panic(expected: ('No data entry found',))]
fn test_data_entry_should_fail_if_not_found_2() {
    //Test should return if the pair_id or the expiration timestamp is not related to a FutureEntry
    let (_, oracle) = setup();
    oracle.get_data_entry(DataType::FutureEntry((100, 110100)), 1, 1);
}

#[test]
#[should_panic(expected: ('No data entry found',))]
fn test_data_entry_should_fail_if_not_found_3() {
    //Test should fail if the pair_id or the expiration timestamp is not related to a FutureEntry
    let (_, oracle) = setup();
    oracle.get_data_entry(DataType::FutureEntry((2, 110100)), 1, 1);
}

#[test]
#[available_gas(20000000000)]
fn test_get_data() {
    let (_, oracle) = setup();
    let entry = oracle.get_data(DataType::SpotEntry(2), AggregationMode::Median(()));
    assert(entry.price == (2500000), 'wrong price');
    let entry = oracle.get_data(DataType::SpotEntry(3), AggregationMode::Median(()));
    assert(entry.price == (8000000), 'wrong price');
    assert(entry.num_sources_aggregated == 1, 'wrong number of sources');
    let entry = oracle.get_data(DataType::SpotEntry(4), AggregationMode::Median(()));
    assert(entry.price == (5500000), 'wrong price');
    assert(entry.num_sources_aggregated == 2, 'wrong number of sources');
    let entry = oracle.get_data(DataType::SpotEntry(5), AggregationMode::Median(()));
    assert(entry.price == (5000000), 'wrong price');
    assert(entry.num_sources_aggregated == 1, 'wrong number of sources');
    let entry = oracle.get_data(DataType::FutureEntry((2, 11111110)), AggregationMode::Median(()));
    assert(entry.price == (2 * 1000000), 'wrong price');
    assert(entry.num_sources_aggregated == 2, 'wrong number of sources');
    let entry = oracle.get_data(DataType::FutureEntry((2, 11111110)), AggregationMode::Median(()));
    assert(entry.price == (2 * 1000000), 'wrong price');
    assert(entry.num_sources_aggregated == 2, 'wrong number of sources');
    let entry = oracle.get_data(DataType::FutureEntry((3, 11111110)), AggregationMode::Median(()));
    assert(entry.price == (3 * 1000000), 'wrong price');
    assert(entry.num_sources_aggregated == 1, 'wrong number of sources');
    let entry = oracle.get_data(DataType::FutureEntry((4, 11111110)), AggregationMode::Median(()));
    assert(entry.price == (4 * 1000000), 'wrong price');
    assert(entry.num_sources_aggregated == 1, 'wrong number of sources');
    let entry = oracle.get_data(DataType::FutureEntry((5, 11111110)), AggregationMode::Median(()));
    assert(entry.price == (5 * 1000000), 'wrong price');
}

fn data_treatment(entry: PossibleEntries) -> (u128, u64, u128) {
    match entry {
        PossibleEntries::Spot(entry) => { (entry.price, entry.base.timestamp, entry.volume) },
        PossibleEntries::Future(entry) => {
            assert(entry.expiration_timestamp == 11111110, 'wrong expiration timestamp');
            (entry.price, entry.base.timestamp, entry.volume)
        },
        PossibleEntries::Generic(entry) => {
            (entry.value.try_into().unwrap(), entry.base.timestamp, 0)
        }
    }
}


#[test]
fn get_data_median() {
    let (_, oracle) = setup();
    let entry = oracle.get_data_median(DataType::SpotEntry(2));
    assert(entry.price == (2500000), 'wrong price');

    let entry = oracle.get_data_median(DataType::SpotEntry(3));
    assert(entry.price == (8000000), 'wrong price');
    assert(entry.num_sources_aggregated == 1, 'wrong number of sources');
    let entry = oracle.get_data_median(DataType::SpotEntry(4));
    assert(entry.price == (5500000), 'wrong price');
    assert(entry.num_sources_aggregated == 2, 'wrong number of sources');
    let entry = oracle.get_data_median(DataType::SpotEntry(5));
    assert(entry.price == (5000000), 'wrong price');
    assert(entry.num_sources_aggregated == 1, 'wrong number of sources');
    let entry = oracle.get_data_median(DataType::FutureEntry((2, 11111110)));
    assert(entry.price == (2 * 1000000), 'wrong price');
    assert(entry.expiration_timestamp.unwrap() == 11111110, 'wrong expiration timestamp');

    assert(entry.num_sources_aggregated == 2, 'wrong number of sources');
    let entry = oracle.get_data_median(DataType::FutureEntry((2, 11111110)));
    assert(entry.price == (2 * 1000000), 'wrong price');
    assert(entry.expiration_timestamp.unwrap() == 11111110, 'wrong expiration timestamp');
    assert(entry.num_sources_aggregated == 2, 'wrong number of sources');
}

#[test]
fn get_data_median_for_sources() {
    let (_, oracle) = setup();
    let mut sources = ArrayTrait::<felt252>::new();
    sources.append(1);
    sources.append(2);
    let entry = oracle.get_data_median_for_sources(DataType::SpotEntry(2), sources.span());
    assert(entry.price == (2500000), 'wrong price');
}
#[test]
#[should_panic(expected: ('No publisher for source',))]
fn get_data_median_for_sources_should_fail_if_wrong_sources() {
    let (_, oracle) = setup();
    let mut sources = ArrayTrait::<felt252>::new();
    // sources.append(1);
    sources.append(3);
    oracle.get_data_median_for_sources(DataType::SpotEntry(2), sources.span());
}
#[test]
fn get_data_for_sources() {
    let (_, oracle) = setup();
    let mut sources = array![1, 2];
    let entry = oracle
        .get_data_for_sources(DataType::SpotEntry(2), AggregationMode::Median(()), sources.span());
    assert(entry.price == (2500000), 'wrong price');
    let entry = oracle
        .get_data_for_sources(
            DataType::FutureEntry((2, 11111110)), AggregationMode::Median(()), sources.span()
        );
    assert(entry.expiration_timestamp.unwrap() == 11111110, 'wrong expiration timestamp');

    assert(entry.price == (2000000), 'wrong price');
}

#[test]
#[available_gas(100000000000)]
fn test_publish_multiple_entries() {
    let (_, oracle) = setup();
    let now = 100000;
    start_cheat_block_timestamp_global(now + 100);
    let entries = array![
        PossibleEntries::Spot(
            SpotEntry {
                base: BaseEntry { timestamp: now + 100, source: 1, publisher: 1 },
                pair_id: 1,
                price: 2 * 1000000,
                volume: 150
            }
        ),
        PossibleEntries::Spot(
            SpotEntry {
                base: BaseEntry { timestamp: now + 100, source: 1, publisher: 1 },
                pair_id: 4,
                price: 2 * 1000000,
                volume: 150
            }
        ),
        PossibleEntries::Spot(
            SpotEntry {
                base: BaseEntry { timestamp: now + 100, source: 1, publisher: 1 },
                pair_id: 3,
                price: 2 * 1000000,
                volume: 20
            }
        ),
        PossibleEntries::Spot(
            SpotEntry {
                base: BaseEntry { timestamp: now + 100, source: 2, publisher: 1 },
                pair_id: 4,
                price: 3 * 1000000,
                volume: 30
            }
        ),
        PossibleEntries::Spot(
            SpotEntry {
                base: BaseEntry { timestamp: now + 100, source: 2, publisher: 1 },
                pair_id: 2,
                price: 3 * 1000000,
                volume: 30
            }
        ),
        PossibleEntries::Spot(
            SpotEntry {
                base: BaseEntry { timestamp: now + 100, source: 2, publisher: 1 },
                pair_id: 3,
                price: 3 * 1000000,
                volume: 30
            }
        ),
    ];
    let sources = array![1, 2];
    oracle.publish_data_entries(entries.span());
    let (entries, _) = oracle.get_data_entries_for_sources(DataType::SpotEntry(4), sources.span());
    let entry_1 = *entries.at(0);
    let (price, timestamp, volume) = data_treatment(entry_1);
    assert(price == 2 * 1000000, 'wrong price(0)');
    assert(timestamp == now + 100, 'wrong  timestamp(0)');
    assert(volume == 150, 'wrong volume(0)');
    let entry_2 = *entries.at(1);
    let (price_2, timestamp_2, volume_2) = data_treatment(entry_2);
    assert(price_2 == 3 * 1000000, 'wrong price(1)');
    assert(timestamp_2 == now + 100, 'wrong timestamp(1)');
    assert(volume_2 == 30, 'wrong volume(1)');
    let (entries_2, _) = oracle
        .get_data_entries_for_sources(DataType::SpotEntry(3), sources.span());
    let entry_3 = *entries_2.at(0);
    let (price_3, timestamp_3, volume_3) = data_treatment(entry_3);
    assert(price_3 == 2 * 1000000, 'wrong price(3)');
    assert(timestamp_3 == now + 100, 'wrong  timestamp(3)');
    assert(volume_3 == 20, 'wrong volume(3)');
    let entry_4 = *entries_2.at(1);
    let (price_4, timestamp_4, volume_4) = data_treatment(entry_4);
    assert(price_4 == 3 * 1000000, 'wrong price(4)');
    assert(timestamp_4 == now + 100, 'wrong timestamp(4)');
    assert(volume_4 == 30, 'wrong volume(4)');
}

#[test]
#[available_gas(100000000000)]
fn test_max_publish_multiple_entries() {
    let (_, oracle) = setup();
    let MAX: u32 = 10;
    let now = 100000;
    let mut entries = ArrayTrait::<PossibleEntries>::new();
    for cur_idx in 0
        ..MAX {
            start_cheat_block_timestamp_global(now + (cur_idx + 1).into() * 100);
            entries
                .append(
                    PossibleEntries::Spot(
                        SpotEntry {
                            base: BaseEntry {
                                timestamp: now + (cur_idx + 1).into() * 100, source: 1, publisher: 1
                            },
                            pair_id: 3,
                            price: 3 * 1000000 + (cur_idx + 1).into(),
                            volume: 30
                        }
                    )
                );
            entries
                .append(
                    PossibleEntries::Spot(
                        SpotEntry {
                            base: BaseEntry {
                                timestamp: now + (cur_idx + 1).into() * 100, source: 2, publisher: 1
                            },
                            pair_id: 2,
                            price: 3 * 1000000 + (cur_idx + 1).into(),
                            volume: 30
                        }
                    )
                );
            entries
                .append(
                    PossibleEntries::Spot(
                        SpotEntry {
                            base: BaseEntry {
                                timestamp: now + (cur_idx + 1).into() * 100, source: 1, publisher: 1
                            },
                            pair_id: 4,
                            price: 3 * 1000000 + (cur_idx + 1).into(),
                            volume: 30
                        }
                    )
                );
        };
    //let sources = array![1, 2];
    oracle.publish_data_entries(entries.span());
    return ();
}

#[test]
fn test_get_data_median_multi() {
    let (_, oracle) = setup();
    let mut sources = ArrayTrait::<felt252>::new();
    sources.append(1);
    sources.append(2);
    let mut data_types = ArrayTrait::<DataType>::new();
    data_types.append(DataType::SpotEntry(2));
    data_types.append(DataType::SpotEntry(4));
    let res = oracle.get_data_median_multi(data_types.span(), sources.span());
    assert(*res.at(0).price == (2500000), 'wrong price');
    assert(*res.at(1).price == (5500000), 'wrong price');
    let mut data_types_2 = ArrayTrait::<DataType>::new();
    data_types_2.append(DataType::FutureEntry((2, 11111110)));
    data_types_2.append(DataType::FutureEntry((5, 11111110)));
    let res_2 = oracle.get_data_median_multi(data_types_2.span(), sources.span());

    assert(*res_2.at(0).price == (2000000), 'wrong price');

    assert(*res_2.at(1).price == (5000000), 'wrong price');
}
#[test]
#[should_panic(expected: ('No publisher for source',))]
fn test_data_median_multi_should_fail_if_wrong_sources() {
    let (_, oracle) = setup();
    let mut sources = ArrayTrait::<felt252>::new();
    sources.append(1);
    sources.append(3);
    let mut data_types = ArrayTrait::<DataType>::new();
    data_types.append(DataType::SpotEntry(2));
    data_types.append(DataType::SpotEntry(3));
    oracle.get_data_median_multi(data_types.span(), sources.span());
}

#[test]
#[should_panic(expected: ('No publisher for source',))]
fn test_data_median_multi_should_fail_if_no_expiration_time_associated() {
    let (_, oracle) = setup();
    let mut sources = ArrayTrait::<felt252>::new();
    sources.append(1);
    sources.append(3);
    let mut data_types = ArrayTrait::<DataType>::new();
    data_types.append(DataType::FutureEntry((2, 111111111)));
    data_types.append(DataType::FutureEntry((3, 111111111)));
    oracle.get_data_median_multi(data_types.span(), sources.span());
}
#[test]
#[should_panic(expected: ('No publisher for source',))]
fn test_data_median_multi_should_fail_if_wrong_data_types() {
    let (_, oracle) = setup();
    let mut sources = ArrayTrait::<felt252>::new();
    sources.append(1);
    sources.append(2);
    let mut data_types = ArrayTrait::<DataType>::new();
    // data_types.append(DataType::SpotEntry(2));
    data_types.append(DataType::SpotEntry(6));
    let res = oracle.get_data_median_multi(data_types.span(), sources.span());
    assert(*res.at(0).price == 2500000, 'wrong price');
    assert(*res.at(1).price == 0, 'wrong price');
}

#[test]
fn test_get_data_with_usd_hop() {
    let (_, oracle) = setup();
    let entry: PragmaPricesResponse = oracle
        .get_data_with_USD_hop(
            111, 222, AggregationMode::Median(()), SimpleDataType::SpotEntry(()), Option::Some(0)
        );
    assert(entry.price == (312500), 'wrong price-usdshop');
    assert(entry.decimals == 6, 'wrong decimals-usdshop');
    let entry_2 = oracle
        .get_data_with_USD_hop(
            111,
            222,
            AggregationMode::Median(()),
            SimpleDataType::FutureEntry(()),
            Option::Some(11111110)
        );
    assert(entry_2.price == (666666), 'wrong price-usdfhop');
    assert(entry_2.decimals == 6, 'wrong decimals-usdfhop');
}

#[test]
fn test_get_data_with_usd_hop_diff() {
    let (_, oracle) = setup();
    let entry = oracle
        .get_data_with_USD_hop(
            'hop', 333, AggregationMode::Median(()), SimpleDataType::SpotEntry(()), Option::Some(0)
        );
    assert(entry.price == 400000, 'wrong price for hop');
    assert(entry.decimals == 6, 'wrong decimals for hop');
}

#[test]
#[should_panic(expected: ('No pair recorded',))]
fn test_get_data_with_USD_hop_should_fail_if_wrong_id() {
    let (_, oracle) = setup();
    oracle
        .get_data_with_USD_hop(
            444, 222, AggregationMode::Median(()), SimpleDataType::SpotEntry(()), Option::Some(0)
        );
}

#[test]
fn test_set_checkpoint() {
    let (_, oracle) = setup();
    oracle.set_checkpoint(DataType::SpotEntry(2), AggregationMode::Median(()));
    let (idx, _) = oracle
        .get_latest_checkpoint_index(DataType::SpotEntry(2), AggregationMode::Median(()));
    let checkpoint: Checkpoint = oracle
        .get_checkpoint(DataType::SpotEntry(2), idx, AggregationMode::Median(()));
    assert(checkpoint.value == (2500000), 'wrong checkpoint');
    assert(checkpoint.num_sources_aggregated == 2, 'wrong num sources');
    oracle.set_checkpoint(DataType::FutureEntry((2, 11111110)), AggregationMode::Median(()));
    let (idx, _) = oracle
        .get_latest_checkpoint_index(
            DataType::FutureEntry((2, 11111110)), AggregationMode::Median(())
        );
    let checkpoint: Checkpoint = oracle
        .get_checkpoint(DataType::FutureEntry((2, 11111110)), idx, AggregationMode::Median(()));
    assert(checkpoint.value == (2000000), 'wrong checkpoint');
    assert(checkpoint.num_sources_aggregated == 2, 'wrong num sources');
}

#[test]
#[should_panic(expected: ('No checkpoint available',))]
fn test_set_checkpoint_should_fail_if_wrong_data_type() {
    let (_, oracle) = setup();
    oracle.set_checkpoint(DataType::SpotEntry(8), AggregationMode::Median(()));
}
#[test]
fn test_get_last_checkpoint_before() {
    let (_, oracle) = setup();
    oracle.set_checkpoint(DataType::SpotEntry(2), AggregationMode::Median(()));
    oracle.set_checkpoint(DataType::FutureEntry((2, 11111110)), AggregationMode::Median(()));

    let (checkpoint, idx) = oracle
        .get_last_checkpoint_before(DataType::SpotEntry(2), 111111111, AggregationMode::Median(()));
    assert(checkpoint.value == (2500000), 'wrong checkpoint');
    assert(idx == 0, 'wrong idx');
    assert(checkpoint.timestamp <= 111111111, 'wrong timestamp');
    let (checkpoint_2, idx_2) = oracle
        .get_last_checkpoint_before(
            DataType::FutureEntry((2, 11111110)), 1111111111, AggregationMode::Median(()),
        );

    assert(checkpoint_2.value == (2000000), 'wrong checkpoint');
    assert(idx_2 == 0, 'wrong idx');
    assert(checkpoint_2.timestamp <= 111111111, 'wrong timestamp');
}

#[test]
#[should_panic(expected: ('Checkpoint does not exist',))]
fn test_get_last_checkpoint_before_should_fail_if_wrong_data_type() {
    let (_, oracle) = setup();
    oracle.set_checkpoint(DataType::SpotEntry(2), AggregationMode::Median(()));
    oracle.set_checkpoint(DataType::FutureEntry((2, 11111110)), AggregationMode::Median(()));

    oracle
        .get_last_checkpoint_before(DataType::SpotEntry(6), 111111111, AggregationMode::Median(()));
}

#[test]
#[should_panic(expected: ('Checkpoint does not exist',))]
fn test_get_last_checkpoint_before_should_fail_if_timestamp_too_old() {
    //if timestamp is before the first checkpoint
    let (_, oracle) = setup();
    oracle.set_checkpoint(DataType::SpotEntry(2), AggregationMode::Median(()));
    oracle.set_checkpoint(DataType::FutureEntry((2, 11111110)), AggregationMode::Median(()));

    oracle.get_last_checkpoint_before(DataType::SpotEntry(6), 111, AggregationMode::Median(()));
}

#[test]
#[should_panic(expected: ('Currency id cannot be 0',))]
fn test_add_currency_should_fail_if_currency_id_null() {
    let (_, oracle) = setup();
    start_cheat_caller_address(oracle.contract_address, owner());
    oracle
        .add_currency(
            Currency {
                id: 0,
                decimals: 18_u32,
                is_abstract_currency: false,
                starknet_address: 0.try_into().unwrap(),
                ethereum_address: 0.try_into().unwrap(),
            }
        );
}

#[test]
#[should_panic(expected: ('No base currency registered',))]
fn test_add_pair_should_panic_if_base_currency_do_not_corresponds() {
    let (_, oracle) = setup();
    start_cheat_caller_address(oracle.contract_address, owner());
    oracle
        .add_pair(
            Pair {
                id: 10,
                quote_currency_id: 111,
                base_currency_id: 1931029312, //wrong base currency id 
            }
        )
}

#[test]
#[should_panic(expected: ('No quote currency registered',))]
fn test_add_pair_should_panic_if_quote_currency_do_not_corresponds() {
    let (_, oracle) = setup();
    start_cheat_caller_address(oracle.contract_address, owner());
    oracle
        .add_pair(Pair { id: 10, quote_currency_id: 123123132, base_currency_id: USD_CURRENCY_ID, })
}

#[test]
fn test_multiple_publishers_price() {
    let (publisher_registry, oracle) = setup();
    start_cheat_caller_address(publisher_registry.contract_address, owner());

    let test_address = contract_address_const::<0x123>();
    publisher_registry.add_publisher(2, test_address);
    // Add source 1 for publisher 1
    publisher_registry.add_source_for_publisher(2, 1);
    // Add source 2 for publisher 1
    publisher_registry.add_source_for_publisher(2, 2);
    let now = 100000;
    start_cheat_caller_address(oracle.contract_address, test_address);
    oracle
        .publish_data(
            PossibleEntries::Spot(
                SpotEntry {
                    base: BaseEntry { timestamp: now, source: 1, publisher: 2 },
                    pair_id: 2,
                    price: 4 * 1000000,
                    volume: 100
                }
            )
        );

    oracle
        .publish_data(
            PossibleEntries::Spot(
                SpotEntry {
                    base: BaseEntry { timestamp: now, source: 2, publisher: 2 },
                    pair_id: 2,
                    price: 5 * 1000000,
                    volume: 50
                }
            )
        );
    oracle
        .publish_data(
            PossibleEntries::Spot(
                SpotEntry {
                    base: BaseEntry { timestamp: now, source: 1, publisher: 2 },
                    pair_id: 3,
                    price: 8 * 1000000,
                    volume: 100
                }
            )
        );
    oracle
        .publish_data(
            PossibleEntries::Spot(
                SpotEntry {
                    base: BaseEntry { timestamp: now, source: 1, publisher: 2 },
                    pair_id: 4,
                    price: 8 * 1000000,
                    volume: 20
                }
            )
        );
    oracle
        .publish_data(
            PossibleEntries::Spot(
                SpotEntry {
                    base: BaseEntry { timestamp: now, source: 2, publisher: 2 },
                    pair_id: 4,
                    price: 3 * 1000000,
                    volume: 10
                }
            )
        );
    oracle
        .publish_data(
            PossibleEntries::Spot(
                SpotEntry {
                    base: BaseEntry { timestamp: now, source: 1, publisher: 2 },
                    pair_id: 5,
                    price: 5 * 1000000,
                    volume: 20
                }
            )
        );
    oracle
        .publish_data(
            PossibleEntries::Future(
                FutureEntry {
                    base: BaseEntry { timestamp: now, source: 1, publisher: 2 },
                    pair_id: 2,
                    price: 2 * 1000000,
                    volume: 40,
                    expiration_timestamp: 11111110
                }
            )
        );
    oracle
        .publish_data(
            PossibleEntries::Future(
                FutureEntry {
                    base: BaseEntry { timestamp: now, source: 2, publisher: 2 },
                    pair_id: 2,
                    price: 2 * 1000000,
                    volume: 30,
                    expiration_timestamp: 11111110
                }
            )
        );
    oracle
        .publish_data(
            PossibleEntries::Future(
                FutureEntry {
                    base: BaseEntry { timestamp: now, source: 1, publisher: 2 },
                    pair_id: 3,
                    price: 3 * 1000000,
                    volume: 1000,
                    expiration_timestamp: 11111110
                }
            )
        );
    oracle
        .publish_data(
            PossibleEntries::Future(
                FutureEntry {
                    base: BaseEntry { timestamp: now, source: 1, publisher: 2 },
                    pair_id: 4,
                    price: 4 * 1000000,
                    volume: 2321,
                    expiration_timestamp: 11111110
                }
            )
        );
    oracle
        .publish_data(
            PossibleEntries::Future(
                FutureEntry {
                    base: BaseEntry { timestamp: now, source: 1, publisher: 2 },
                    pair_id: 5,
                    price: 5 * 1000000,
                    volume: 231,
                    expiration_timestamp: 11111110
                }
            )
        );
    oracle
        .publish_data(
            PossibleEntries::Future(
                FutureEntry {
                    base: BaseEntry { timestamp: now, source: 2, publisher: 2 },
                    pair_id: 5,
                    price: 5 * 1000000,
                    volume: 232,
                    expiration_timestamp: 11111110
                }
            )
        );
    let entry = oracle.get_data(DataType::SpotEntry(2), AggregationMode::Median(()));
    assert(entry.price == (3500000), 'wrong price');
    assert(entry.num_sources_aggregated == 2, 'wrong number of sources');
    let entry = oracle.get_data(DataType::SpotEntry(3), AggregationMode::Median(()));
    assert(entry.price == (8000000), 'wrong price');
    assert(entry.num_sources_aggregated == 1, 'wrong number of sources');
    let entry = oracle.get_data(DataType::SpotEntry(4), AggregationMode::Median(()));
    assert(entry.price == (5500000), 'wrong price');
    assert(entry.num_sources_aggregated == 2, 'wrong number of sources');
    let entry = oracle.get_data(DataType::SpotEntry(5), AggregationMode::Median(()));
    assert(entry.price == (5000000), 'wrong price');
    assert(entry.num_sources_aggregated == 1, 'wrong number of sources');
    let entry = oracle.get_data(DataType::FutureEntry((2, 11111110)), AggregationMode::Median(()));
    assert(entry.price == (2 * 1000000), 'wrong price');
    assert(entry.num_sources_aggregated == 2, 'wrong number of sources');
    let entry = oracle.get_data(DataType::FutureEntry((2, 11111110)), AggregationMode::Median(()));
    assert(entry.price == (2 * 1000000), 'wrong price');
    assert(entry.num_sources_aggregated == 2, 'wrong number of sources');
    let entry = oracle.get_data(DataType::FutureEntry((3, 11111110)), AggregationMode::Median(()));
    assert(entry.price == (3 * 1000000), 'wrong price');
    assert(entry.num_sources_aggregated == 1, 'wrong number of sources');
    let entry = oracle.get_data(DataType::FutureEntry((4, 11111110)), AggregationMode::Median(()));
    assert(entry.price == (4 * 1000000), 'wrong price');
    assert(entry.num_sources_aggregated == 1, 'wrong number of sources');
    let entry = oracle.get_data(DataType::FutureEntry((5, 11111110)), AggregationMode::Median(()));
    assert(entry.price == (5 * 1000000), 'wrong price');
}
#[test]
fn test_get_data_entry_for_publishers() {
    let admin = contract_address_const::<0x123456789>();
    let (publisher_registry, oracle) = setup();
    let test_address = contract_address_const::<0x1234567>();
    start_cheat_caller_address(oracle.contract_address, admin);
    publisher_registry.add_publisher(2, test_address);
    // Add source 1 for publisher 1
    publisher_registry.add_source_for_publisher(2, 1);
    // Add source 2 for publisher 1
    publisher_registry.add_source_for_publisher(2, 2);
    let now = 100000;
    start_cheat_caller_address(oracle.contract_address, test_address);
    oracle
        .publish_data(
            PossibleEntries::Spot(
                SpotEntry {
                    base: BaseEntry { timestamp: now, source: 1, publisher: 2 },
                    pair_id: 2,
                    price: 4 * 1000000,
                    volume: 120
                }
            )
        );
    oracle
        .publish_data(
            PossibleEntries::Future(
                FutureEntry {
                    base: BaseEntry { timestamp: now, source: 1, publisher: 2 },
                    pair_id: 2,
                    price: 4 * 1000000,
                    volume: 120,
                    expiration_timestamp: 11111110
                }
            )
        );

    let entry = oracle.get_data_entry_for_publishers(DataType::SpotEntry(2), 1);
    match entry {
        PossibleEntries::Spot(entry) => {
            assert(entry.price == (3000000), 'wrong price');
            assert(entry.volume == 110, 'wrong volume');
        },
        _ => { assert(false, 'wrong entry type'); }
    }
    let entry = oracle.get_data_entry_for_publishers(DataType::FutureEntry((2, 11111110)), 1);
    match entry {
        PossibleEntries::Future(entry) => {
            assert(entry.price == (3000000), 'wrong price');
            assert(entry.volume == 80, 'wrong volume');
        },
        _ => { assert(false, 'wrong entry type'); }
    }
    let test_address_2 = contract_address_const::<0x1234567314>();
    start_cheat_caller_address(oracle.contract_address, admin);
    publisher_registry.add_publisher(3, test_address_2);
    // Add source 1 for publisher 1
    publisher_registry.add_source_for_publisher(3, 1);
    // Add source 2 for publisher 1
    publisher_registry.add_source_for_publisher(3, 2);
    start_cheat_caller_address(oracle.contract_address, test_address_2);
    oracle
        .publish_data(
            PossibleEntries::Spot(
                SpotEntry {
                    base: BaseEntry { timestamp: now, source: 1, publisher: 3 },
                    pair_id: 2,
                    price: 7 * 1000000,
                    volume: 150
                }
            )
        );
    oracle
        .publish_data(
            PossibleEntries::Future(
                FutureEntry {
                    base: BaseEntry { timestamp: now, source: 1, publisher: 3 },
                    pair_id: 2,
                    price: 7 * 1000000,
                    volume: 150,
                    expiration_timestamp: 11111110
                }
            )
        );
    let entry = oracle.get_data_entry_for_publishers(DataType::SpotEntry(2), 1);

    match entry {
        PossibleEntries::Spot(entry) => {
            assert(entry.price == (4000000), 'wrong price');
            assert(entry.volume == 120, 'wrong volume');
        },
        _ => { assert(false, 'wrong entry type'); }
    }
    let entry = oracle.get_data_entry_for_publishers(DataType::FutureEntry((2, 11111110)), 1);
    match entry {
        PossibleEntries::Future(entry) => {
            assert(entry.price == (4000000), 'wrong price');
            assert(entry.volume == 120, 'wrong volume');
        },
        _ => { assert(false, 'wrong entry type'); }
    }
}


#[test]
fn test_get_all_publishers() {
    let now = 100000;
    let (publisher_registry, oracle) = setup();
    let publishers = oracle.get_all_publishers(DataType::SpotEntry(2));
    assert(publishers.len() == 1, 'wrong number of publishers(S)');
    assert(*publishers.at(0) == 1, 'wrong publisher(S)');
    let test_address = contract_address_const::<0x1234567>();

    publisher_registry.add_publisher(2, test_address);
    // Add source 1 for publisher 1
    publisher_registry.add_source_for_publisher(2, 1);
    // Add source 2 for publisher 1
    publisher_registry.add_source_for_publisher(2, 2);
    start_cheat_caller_address(oracle.contract_address, test_address);
    oracle
        .publish_data(
            PossibleEntries::Spot(
                SpotEntry {
                    base: BaseEntry { timestamp: now, source: 1, publisher: 2 },
                    pair_id: 2,
                    price: 4 * 1000000,
                    volume: 120
                }
            )
        );
    let publishers = oracle.get_all_publishers(DataType::SpotEntry(2));
    assert(publishers.len() == 2, 'wrong number of publishers(S)');
    assert(*publishers.at(0) == 1, 'wrong publisher(S)');
    assert(*publishers.at(1) == 2, 'wrong publisher(S)');
    let future_publishers = oracle.get_all_publishers(DataType::FutureEntry((2, 11111110)));
    assert(future_publishers.len() == 1, 'wrong number of publishers(F)');
    assert(*future_publishers.at(0) == 1, 'wrong publisher(F)');
}

#[test]
fn test_get_all_sources() {
    let (_, oracle) = setup();
    let sources = oracle.get_all_sources(DataType::SpotEntry(2));
    assert(sources.len() == 2, 'wrong number of sources(S)');
    assert(*sources.at(0) == 1, 'wrong source(S)');
    assert(*sources.at(1) == 2, 'wrong source(S)');
    let future_sources = oracle.get_all_sources(DataType::FutureEntry((2, 11111110)));
    assert(future_sources.len() == 2, 'wrong number of sources(F)');
    assert(*future_sources.at(0) == 1, 'wrong source(F)');
    assert(*future_sources.at(1) == 2, 'wrong source(F)');
}

// #[test]
// // fn test_remove_source() {
//     let (publisher_registry, oracle) = setup();
//     let admin = contract_address_const::<0x123456789>();
//     start_cheat_caller_address(oracle.contract_address,admin);
//     publisher_registry.add_source_for_publisher(1, 3);
//     let now = 100000;
//     oracle
//         .publish_data(
//             PossibleEntries::Spot(
//                 SpotEntry {
//                     base: BaseEntry { timestamp: now, source: 3, publisher: 1 },
//                     pair_id: 2,
//                     price: 7 * 1000000,
//                     volume: 150
//                 }
//             )
//         );
//     oracle
//         .publish_data(
//             PossibleEntries::Future(
//                 FutureEntry {
//                     base: BaseEntry { timestamp: now - 10000, source: 3, publisher: 1 },
//                     pair_id: 2,
//                     price: 7 * 1000000,
//                     volume: 150,
//                     expiration_timestamp: 11111110
//                 }
//             )
//         );
//     let sources = array![3];
//     let entry = oracle
//         .get_data_for_sources(DataType::SpotEntry(2), AggregationMode::Median(()),
//         sources.span());
//     assert(entry.price == (7000000), 'wrong price');
//     assert(entry.num_sources_aggregated == 1, 'wrong number of sources');
//     let boolean: bool = oracle.remove_source(3, DataType::SpotEntry(2));
//     assert(boolean == true, 'operation failed');
// }

#[test]
#[available_gas(20000000000)]
fn test_publishing_data_for_less_sources_than_initially_planned() {
    let (publisher_registry, oracle) = setup();
    let now = 100000;
    start_cheat_caller_address(oracle.contract_address, owner());
    publisher_registry.add_source_for_publisher(1, 3);
    start_cheat_caller_address(oracle.contract_address, publisher_address());
    oracle
        .publish_data(
            PossibleEntries::Spot(
                SpotEntry {
                    base: BaseEntry { timestamp: now + 9000, source: 3, publisher: 1 },
                    pair_id: 2,
                    price: 7 * 1000000,
                    volume: 150,
                }
            )
        );
    let data_sources = oracle.get_all_sources(DataType::SpotEntry(2));
    assert(data_sources.len() == 3, 'wrong number of sources');
    start_cheat_block_timestamp_global(now + 10000);
    let entries = oracle.get_data_entries(DataType::SpotEntry(2));
    assert(entries.len() == 1, 'wrong number of entries');
    let data = oracle.get_data(DataType::SpotEntry(2), AggregationMode::Median(()));
    assert(data.price == 7000000, 'wrong price');
}


#[test]
fn test_update_pair() {
    let (_, oracle) = setup();
    start_cheat_caller_address(oracle.contract_address, owner());
    let pair = oracle.get_pair(1);
    assert(pair.id == 1, 'wrong pair fetched');
    assert(pair.quote_currency_id == 111, 'wrong recorded pair');
    assert(pair.base_currency_id == 222, 'wrong recorded pair');
    oracle
        .add_currency(
            Currency {
                id: 12345,
                decimals: 18_u32,
                is_abstract_currency: false,
                starknet_address: 0.try_into().unwrap(),
                ethereum_address: 0.try_into().unwrap(),
            }
        );
    oracle
        .update_pair(
            1,
            Pair {
                id: 1, quote_currency_id: 111, base_currency_id: 12345, //wrong base currency id 
            }
        );
    let pair = oracle.get_pair(1);
    assert(pair.id == 1, 'wrong pair fetched');
    assert(pair.quote_currency_id == 111, 'wrong recorded pair');
    assert(pair.base_currency_id == 12345, 'wrong recorded pair');
}
