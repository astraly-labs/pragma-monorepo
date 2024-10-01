use pragma_entry::structures::{
    USD_CURRENCY_ID, OptionsFeedData, GenericEntry, Currency, Pair, SpotEntry, FutureEntry,
    PragmaPricesResponse, BaseEntry, Checkpoint, SimpleDataType, PossibleEntries, AggregationMode,
    DataType
};
use pragma_oracle::interface::{IOracleABIDispatcher, IOracleABIDispatcherTrait};
use pragma_publisher_registry::interface::{
    IPublisherRegistryABIDispatcher, IPublisherRegistryABIDispatcherTrait
};
use pragma_summary_stats::interface::{
    ISummaryStatsABIDispatcher, ISummaryStatsABIDispatcherTrait, DERIBIT_OPTIONS_FEED_ID
};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    start_cheat_block_timestamp_global, stop_cheat_caller_address, spy_events,
    EventSpyAssertionsTrait
};
use starknet::{ContractAddress, contract_address_const};
const NOW: u64 = 100000;

fn owner() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

fn publisher_address() -> ContractAddress {
    contract_address_const::<'PUBLISHER_1'>()
}

fn setup() -> (ISummaryStatsABIDispatcher, IOracleABIDispatcher) {
    start_cheat_block_timestamp_global(NOW);

    // Deploy PublisherRegistry
    let publisher_registry = deploy_publisher_registry();

    // Setup currencies and pairs
    let address = contract_address_const::<0>();
    let currencies = array![
        (111, 18_u32, false, address, address),
        (222, 18_u32, false, address, address),
        (USD_CURRENCY_ID, 6_u32, false, address, address),
        (333, 18_u32, false, address, address),
    ];

    let pairs = array![(1, 111, 222), (2, 111, USD_CURRENCY_ID),];

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
    let oracle = IOracleABIDispatcher { contract_address: oracle_address };

    // Deploy SummaryStats
    let mut summary_calldata = ArrayTrait::<felt252>::new();
    oracle_address.serialize(ref summary_calldata);
    let summary_stats = declare("SummaryStats").unwrap().contract_class();
    let (summary_stats_address, _) = summary_stats.deploy(@summary_calldata).unwrap();
    let summary_stats = ISummaryStatsABIDispatcher { contract_address: summary_stats_address };

    // Publish data points
    publish_spot_entries_with_checkpoints(oracle);

    (summary_stats, oracle)
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
    dispatcher.add_source_for_publisher(1, 3);

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


fn publish_spot_entries_with_checkpoints(oracle: IOracleABIDispatcher) {
    start_cheat_caller_address(oracle.contract_address, publisher_address());
    oracle
        .publish_data(
            PossibleEntries::Spot(
                SpotEntry {
                    base: BaseEntry { timestamp: NOW, source: 1, publisher: 1 },
                    pair_id: 2,
                    price: 2 * 1000000,
                    volume: 0
                }
            )
        );
    oracle
        .publish_data(
            PossibleEntries::Spot(
                SpotEntry {
                    base: BaseEntry { timestamp: NOW, source: 2, publisher: 1 },
                    pair_id: 2,
                    price: 3 * 1000000,
                    volume: 0
                }
            )
        );

    //checkpoint = 250000 (Median)
    oracle.set_checkpoint(DataType::SpotEntry(2), AggregationMode::Median(()));
    oracle.set_checkpoint(DataType::SpotEntry(2), AggregationMode::Mean(()));

    start_cheat_block_timestamp_global(NOW + 101);
    oracle
        .publish_data(
            PossibleEntries::Spot(
                SpotEntry {
                    base: BaseEntry { timestamp: NOW + 100, source: 2, publisher: 1 },
                    pair_id: 2,
                    price: 35 * 100000,
                    volume: 0
                }
            )
        );

    //checkpoint = 275000 (Median)
    oracle.set_checkpoint(DataType::SpotEntry(2), AggregationMode::Median(()));
    oracle.set_checkpoint(DataType::SpotEntry(2), AggregationMode::Mean(()));

    start_cheat_block_timestamp_global(NOW + 200);
    oracle
        .publish_data(
            PossibleEntries::Spot(
                SpotEntry {
                    base: BaseEntry { timestamp: NOW + 200, source: 2, publisher: 1 },
                    pair_id: 2,
                    price: 4 * 1000000,
                    volume: 0
                }
            )
        );

    //checkpoint = 300000 (Median)
    oracle.set_checkpoint(DataType::SpotEntry(2), AggregationMode::Median(()));
    oracle.set_checkpoint(DataType::SpotEntry(2), AggregationMode::Mean(()));
    start_cheat_block_timestamp_global(NOW + 300);
    oracle
        .publish_data(
            PossibleEntries::Spot(
                SpotEntry {
                    base: BaseEntry { timestamp: NOW + 300, source: 2, publisher: 1 },
                    pair_id: 2,
                    price: 4 * 1000000,
                    volume: 0
                }
            )
        );
    //checkpoint = 300000 (Median)
    oracle.set_checkpoint(DataType::SpotEntry(2), AggregationMode::Median(()));
    oracle.set_checkpoint(DataType::SpotEntry(2), AggregationMode::Mean(()));
    start_cheat_block_timestamp_global(NOW + 400);
    oracle
        .publish_data(
            PossibleEntries::Spot(
                SpotEntry {
                    base: BaseEntry { timestamp: NOW + 400, source: 2, publisher: 1 },
                    pair_id: 2,
                    price: 3 * 1000000,
                    volume: 0
                }
            )
        );
    //checkpoint = 250000 (Median)
    oracle.set_checkpoint(DataType::SpotEntry(2), AggregationMode::Median(()));
    oracle.set_checkpoint(DataType::SpotEntry(2), AggregationMode::Mean(()));
}


fn setup_twap() -> (ISummaryStatsABIDispatcher, IOracleABIDispatcher) {
    // Deploy PublisherRegistry
    let publisher_registry = deploy_publisher_registry();

    let NOW = 100000;
    start_cheat_block_timestamp_global(NOW);

    // Setup currencies
    let address = contract_address_const::<0>();
    let currencies = array![
        (111, 18_u32, false, address, address),
        (222, 18_u32, false, address, address),
        (USD_CURRENCY_ID, 6_u32, false, address, address),
        (333, 18_u32, false, address, address),
    ];

    // Setup pairs
    let pairs = array![(1, 111, 222), (2, 111, USD_CURRENCY_ID), (3, 222, USD_CURRENCY_ID),];

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
    let oracle = IOracleABIDispatcher { contract_address: oracle_address };

    // Deploy SummaryStats
    let mut summary_calldata = ArrayTrait::<felt252>::new();
    oracle_address.serialize(ref summary_calldata);
    let summary_stats = declare("SummaryStats").unwrap().contract_class();
    let (summary_stats_address, _) = summary_stats.deploy(@summary_calldata).unwrap();
    let summary_stats = ISummaryStatsABIDispatcher { contract_address: summary_stats_address };

    // Start pranking as publisher
    start_cheat_caller_address(oracle.contract_address, publisher_address());

    // Publish future entries and set checkpoints
    publish_future_entries_and_checkpoints(oracle, NOW);

    (summary_stats, oracle)
}

fn publish_future_entries_and_checkpoints(oracle: IOracleABIDispatcher, NOW: u64) {
    let expiration_timestamp = 11111110;

    // First batch of entries
    oracle
        .publish_data(
            PossibleEntries::Future(
                FutureEntry {
                    base: BaseEntry { timestamp: NOW, source: 1, publisher: 1 },
                    pair_id: 2,
                    price: 2 * 1000000,
                    volume: 100,
                    expiration_timestamp
                }
            )
        );
    oracle
        .set_checkpoint(
            DataType::FutureEntry((2, expiration_timestamp)), AggregationMode::Median(())
        );

    // 200 timestamp increment
    start_cheat_block_timestamp_global(NOW + 200);
    oracle
        .publish_data(
            PossibleEntries::Future(
                FutureEntry {
                    base: BaseEntry { timestamp: NOW + 200, source: 1, publisher: 1 },
                    pair_id: 2,
                    price: 8 * 1000000,
                    volume: 100,
                    expiration_timestamp
                }
            )
        );
    oracle
        .set_checkpoint(
            DataType::FutureEntry((2, expiration_timestamp)), AggregationMode::Median(())
        );

    // 400 timestamp increment
    start_cheat_block_timestamp_global(NOW + 400);
    oracle
        .publish_data(
            PossibleEntries::Future(
                FutureEntry {
                    base: BaseEntry { timestamp: NOW + 400, source: 1, publisher: 1 },
                    pair_id: 2,
                    price: 3 * 1000000,
                    volume: 100,
                    expiration_timestamp
                }
            )
        );
    oracle
        .set_checkpoint(
            DataType::FutureEntry((2, expiration_timestamp)), AggregationMode::Median(())
        );

    // 600 timestamp increment
    start_cheat_block_timestamp_global(NOW + 600);
    oracle
        .publish_data(
            PossibleEntries::Future(
                FutureEntry {
                    base: BaseEntry { timestamp: NOW + 600, source: 1, publisher: 1 },
                    pair_id: 2,
                    price: 5 * 1000000,
                    volume: 100,
                    expiration_timestamp
                }
            )
        );
    oracle
        .set_checkpoint(
            DataType::FutureEntry((2, expiration_timestamp)), AggregationMode::Median(())
        );

    // Reset timestamp for pair 3
    start_cheat_block_timestamp_global(NOW);

    // Publish multiple sources for pair 3
    let pair_3_entries = array![(1, 2 * 1000000), (2, 4 * 1000000), (3, 6 * 1000000),];

    for i in 0
        ..pair_3_entries
            .len() {
                let (source, price) = *pair_3_entries[i];
                oracle
                    .publish_data(
                        PossibleEntries::Future(
                            FutureEntry {
                                base: BaseEntry { timestamp: NOW, source, publisher: 1 },
                                pair_id: 3,
                                price,
                                volume: 100,
                                expiration_timestamp
                            }
                        )
                    );
            };
    oracle
        .set_checkpoint(
            DataType::FutureEntry((3, expiration_timestamp)), AggregationMode::Median(())
        );

    // 200 timestamp increment for pair 3
    start_cheat_block_timestamp_global(NOW + 200);
    oracle
        .publish_data(
            PossibleEntries::Future(
                FutureEntry {
                    base: BaseEntry { timestamp: NOW + 200, source: 1, publisher: 1 },
                    pair_id: 3,
                    price: 8 * 1000000,
                    volume: 100,
                    expiration_timestamp
                }
            )
        );
    oracle
        .publish_data(
            PossibleEntries::Future(
                FutureEntry {
                    base: BaseEntry { timestamp: NOW + 200, source: 2, publisher: 1 },
                    pair_id: 3,
                    price: 8 * 1000000,
                    volume: 100,
                    expiration_timestamp
                }
            )
        );
    oracle
        .set_checkpoint(
            DataType::FutureEntry((3, expiration_timestamp)), AggregationMode::Median(())
        );

    // 400 timestamp increment for pair 3
    start_cheat_block_timestamp_global(NOW + 400);
    let pair_3_entries_400 = array![(1, 2 * 1000000), (2, 3 * 1000000), (3, 4 * 1000000),];

    for i in 0
        ..pair_3_entries_400
            .len() {
                let (source, price) = *pair_3_entries_400[i];
                oracle
                    .publish_data(
                        PossibleEntries::Future(
                            FutureEntry {
                                base: BaseEntry { timestamp: NOW + 400, source, publisher: 1 },
                                pair_id: 3,
                                price,
                                volume: 100,
                                expiration_timestamp
                            }
                        )
                    );
            };
    oracle
        .set_checkpoint(
            DataType::FutureEntry((3, expiration_timestamp)), AggregationMode::Median(())
        );

    // 600 timestamp increment for pair 3
    start_cheat_block_timestamp_global(NOW + 600);
    oracle
        .publish_data(
            PossibleEntries::Future(
                FutureEntry {
                    base: BaseEntry { timestamp: NOW + 600, source: 1, publisher: 1 },
                    pair_id: 3,
                    price: 5 * 1000000,
                    volume: 100,
                    expiration_timestamp
                }
            )
        );
    oracle
        .set_checkpoint(
            DataType::FutureEntry((3, expiration_timestamp)), AggregationMode::Median(())
        );
}


#[test]
fn test_summary_stats_mean_median() {
    let (summary_stats, oracle) = setup();
    start_cheat_block_timestamp_global(NOW + 101);
    let (mean, _) = summary_stats
        .calculate_mean(
            DataType::SpotEntry(2), 100000, (100002 + 400), AggregationMode::Median(())
        );
    assert(mean == 2750000, 'wrong median(1)');
    let (mean_1, _) = summary_stats
        .calculate_mean(DataType::SpotEntry(2), 100000, (100002), AggregationMode::Median(()));
    assert(mean_1 == 2500000, 'wrong median(2)');
    let (mean_2, _) = summary_stats
        .calculate_mean(
            DataType::SpotEntry(2), 100000, (100002 + 100), AggregationMode::Median(())
        );

    assert(mean_2 == 2625000, 'wrong median(3)');
    let (mean_3, _) = summary_stats
        .calculate_mean(
            DataType::SpotEntry(2), 100002, (100002 + 200), AggregationMode::Median(())
        );
    assert(mean_3 == 2750000, 'wrong median(4)');
    let (mean_4, _) = summary_stats
        .calculate_mean(
            DataType::SpotEntry(2), 100002, (100002 + 300), AggregationMode::Median(())
        );
    assert(mean_4 == 2812500, 'wrong median(5)');
    let (mean_5, _) = summary_stats
        .calculate_mean(
            DataType::SpotEntry(2), 100202, (100002 + 400), AggregationMode::Median(())
        );
    assert(mean_5 == 2833333, 'wrong median(6)');
}


#[test]
fn test_summary_stats_mean_mean() {
    let (summary_stats, oracle) = setup();
    let (mean, _) = summary_stats
        .calculate_mean(DataType::SpotEntry(2), 100000, (100002 + 400), AggregationMode::Mean(()));
    assert(mean == 2750000, 'wrong mean(1)');
    let (mean_1, _) = summary_stats
        .calculate_mean(DataType::SpotEntry(2), 100000, (100002), AggregationMode::Mean(()));
    assert(mean_1 == 2500000, 'wrong mean(2)');
    let (mean_2, _) = summary_stats
        .calculate_mean(DataType::SpotEntry(2), 100000, (100002 + 100), AggregationMode::Mean(()));
    assert(mean_2 == 2625000, 'wrong mean(3)');
    let (mean_3, _) = summary_stats
        .calculate_mean(DataType::SpotEntry(2), 100002, (100002 + 200), AggregationMode::Mean(()));
    assert(mean_3 == 2750000, 'wrong mean(4)');
    let (mean_4, _) = summary_stats
        .calculate_mean(DataType::SpotEntry(2), 100002, (100002 + 300), AggregationMode::Mean(()));
    assert(mean_4 == 2812500, 'wrong mean(5)');
    let (mean_5, _) = summary_stats
        .calculate_mean(DataType::SpotEntry(2), 100200, (100002 + 400), AggregationMode::Mean(()));
    assert(mean_5 == 2833333, 'wrong mean(6)');
}

#[test]
fn test_set_future_checkpoint() {
    let admin = contract_address_const::<0x123456789>();
    let (summary_stats, oracle) = setup_twap();
    start_cheat_caller_address(oracle.contract_address, admin);

    let (twap_test, decimals) = summary_stats
        .calculate_twap(
            DataType::FutureEntry((2, 11111110)), AggregationMode::Median(()), 10000, 100001
        );
    assert(twap_test == 4333333, 'wrong twap(1)');
    assert(decimals == 6, 'wrong decimals(1)');
    let (twap_test_2, decimals) = summary_stats
        .calculate_twap(
            DataType::FutureEntry((2, 11111110)), AggregationMode::Median(()), 10000, 100201
        );

    assert(twap_test_2 == 5500000, 'wrong twap(2)');
    assert(decimals == 6, 'wrong decimals(2)');
    let (twap_test_3, decimals) = summary_stats
        .calculate_twap(
            DataType::FutureEntry((2, 11111110)), AggregationMode::Median(()), 10000, 100401
        );
    assert(twap_test_3 == 3000000, 'wrong twap(3)');
    assert(decimals == 6, 'wrong decimals(3)');
    let (twap_test_4, decimals) = summary_stats
        .calculate_twap(
            DataType::FutureEntry((3, 11111110)), AggregationMode::Median(()), 10000, 100001
        );
    assert(twap_test_4 == 5000000, 'wrong twap(4)');
    assert(decimals == 6, 'wrong decimals(4)');
    let (twap_test_5, decimals) = summary_stats
        .calculate_twap(
            DataType::FutureEntry((3, 11111110)), AggregationMode::Median(()), 10000, 100201
        );
    assert(twap_test_5 == 5500000, 'wrong twap(5)');
    assert(decimals == 6, 'wrong decimals(5)');
    let (twap_test_6, decimals) = summary_stats
        .calculate_twap(
            DataType::FutureEntry((3, 11111110)), AggregationMode::Median(()), 10000, 100401
        );
    assert(twap_test_6 == 3000000, 'wrong twap(6)');
    return ();
}

/// Mock data has been computed in the pragma-node repository
#[test]
fn test_update_options_data() {
    let (summary_stats, oracle) = setup_twap();
    start_cheat_caller_address(oracle.contract_address, publisher_address());

    // Publish generic entry
    let NOW = 100000;
    let source = 1;
    let publisher = 1;
    let merkle_root: felt252 = 0x31d84dd2db2edb4b74a651b0f86351612efdedc51b51a178d5967a3cdfd319f;
    let base = BaseEntry { timestamp: NOW, source, publisher };
    let generic_entry = GenericEntry {
        base, key: DERIBIT_OPTIONS_FEED_ID, value: merkle_root.into()
    };

    oracle.publish_data(PossibleEntries::Generic(generic_entry));

    let data_entry = oracle
        .get_data_entries(DataType::GenericEntry(DERIBIT_OPTIONS_FEED_ID))
        .get(0);

    // Update options data
    let mut merkle_proof = ArrayTrait::<felt252>::new();
    merkle_proof.append(0x78626d4f8f1e24c24a41d90457688b436463d7595c4dd483671b1d5297518d2);
    merkle_proof.append(0x14eb21a8e98fbd61f20d0bbdba2b32cb2bcb61082dfcf5229370aca5b2dbd2);
    merkle_proof.append(0x73a5b6ab2f3ed2647ed316e5d4acac4db4b5f8da8f6e4707e633ebe02006043);
    merkle_proof.append(0x1c156b5dedc44a27e73968ebe3d464538d7bb0332f1c8191b2eb4a5afca8c7a);
    merkle_proof.append(0x39b52ee5f605f57cc893d398b09cb558c87ec9c956e11cd066df82e1006b33b);
    merkle_proof.append(0x698ea138d770764c65cb171627c57ebc1efb7c495b2c7098872cb485fd2e0bc);
    merkle_proof.append(0x313f2d7dc97dabc9a7fea0b42a5357787cabe78cdcca0d8274eabe170aaa79d);
    merkle_proof.append(0x6b35594ee638d1baa9932b306753fbd43a300435af0d51abd3dd7bd06159e80);
    merkle_proof.append(0x6e9f8a80ebebac7ba997448a1c50cd093e1b9c858cac81537446bafa4aa9431);
    merkle_proof.append(0x3082dc1a8f44267c1b9bea29a3df4bd421e9c33ee1594bf297a94dfd34c7ae4);
    merkle_proof.append(0x16356d27fc23e31a3570926c593bb37430201f51282f2628780264d3a399867);

    let instrument_name = 'BTC-16AUG24-52000-P';

    let update_data: OptionsFeedData = OptionsFeedData {
        instrument_name: instrument_name,
        base_currency_id: 'BTC',
        current_timestamp: 1722805873,
        mark_price: 45431835920,
    };

    let leaf = summary_stats.get_options_data_hash(update_data);

    assert(leaf == 0x7866fd2ec3bc6bd1a2efb6e1f02337d62064a86e8d5755bdc568d92a06f320a, 'wrong leaf');

    summary_stats.update_options_data(merkle_proof.span(), update_data);

    // Check that storage was updated
    let updated_data = summary_stats.get_options_data(instrument_name);
    assert(updated_data == update_data, 'wrong data');
}

#[test]
#[should_panic(expected: ('Invalid proof',))]
fn test_update_options_data_fail_with_invalid_data() {
    let (summary_stats, oracle) = setup_twap();
    start_cheat_caller_address(oracle.contract_address, publisher_address());

    // Publish generic entry
    let NOW = 100000;
    let source = 1;
    let publisher = 1;
    let merkle_root: felt252 = 0x31d84dd2db2edb4b74a651b0f86351612efdedc51b51a178d5967a3cdfd319f;
    let base = BaseEntry { timestamp: NOW, source, publisher };
    let generic_entry = GenericEntry {
        base, key: DERIBIT_OPTIONS_FEED_ID, value: merkle_root.into()
    };

    oracle.publish_data(PossibleEntries::Generic(generic_entry));

    let data_entry = oracle
        .get_data_entries(DataType::GenericEntry(DERIBIT_OPTIONS_FEED_ID))
        .get(0);

    // Update options data
    let mut merkle_proof = ArrayTrait::<felt252>::new();
    merkle_proof.append(0x78626d4f8f1e24c24a41d90457688b436463d7595c4dd483671b1d5297518d2);
    merkle_proof.append(0x14eb21a8e98fbd61f20d0bbdba2b32cb2bcb61082dfcf5229370aca5b2dbd2);
    merkle_proof.append(0x73a5b6ab2f3ed2647ed316e5d4acac4db4b5f8da8f6e4707e633ebe02006043);
    merkle_proof.append(0x1c156b5dedc44a27e73968ebe3d464538d7bb0332f1c8191b2eb4a5afca8c7a);
    merkle_proof.append(0x39b52ee5f605f57cc893d398b09cb558c87ec9c956e11cd066df82e1006b33b);
    merkle_proof.append(0x698ea138d770764c65cb171627c57ebc1efb7c495b2c7098872cb485fd2e0bc);
    merkle_proof.append(0x313f2d7dc97dabc9a7fea0b42a5357787cabe78cdcca0d8274eabe170aaa79d);
    merkle_proof.append(0x6b35594ee638d1baa9932b306753fbd43a300435af0d51abd3dd7bd06159e80);
    merkle_proof.append(0x6e9f8a80ebebac7ba997448a1c50cd093e1b9c858cac81537446bafa4aa9431);
    merkle_proof.append(0x3082dc1a8f44267c1b9bea29a3df4bd421e9c33ee1594bf297a94dfd34c7ae4);
    merkle_proof.append(0x16356d27fc23e31a3570926c593bb37430201f51282f2628780264d3a399867);

    let instrument_name = 'BTC-16AUG24-52000-P';

    let update_data: OptionsFeedData = OptionsFeedData {
        instrument_name: instrument_name,
        base_currency_id: 'ETH', // Invalid base currency
        current_timestamp: 1722805873,
        mark_price: 45431835920,
    };

    let leaf = summary_stats.get_options_data_hash(update_data);

    summary_stats.update_options_data(merkle_proof.span(), update_data);
}

#[test]
#[should_panic(expected: ('Invalid proof',))]
fn test_update_options_data_fail_with_invalid_proof() {
    let (summary_stats, oracle) = setup_twap();
    start_cheat_caller_address(oracle.contract_address, publisher_address());

    // Publish generic entry
    let NOW = 100000;
    let source = 1;
    let publisher = 1;
    let merkle_root: felt252 = 0x31d84dd2db2edb4b74a651b0f86351612efdedc51b51a178d5967a3cdfd319f;
    let base = BaseEntry { timestamp: NOW, source, publisher };
    let generic_entry = GenericEntry {
        base, key: DERIBIT_OPTIONS_FEED_ID, value: merkle_root.into()
    };

    oracle.publish_data(PossibleEntries::Generic(generic_entry));

    let data_entry = oracle
        .get_data_entries(DataType::GenericEntry(DERIBIT_OPTIONS_FEED_ID))
        .get(0);

    // Update options data
    let mut merkle_proof = ArrayTrait::<felt252>::new();
    merkle_proof.append(0x78626d4f8f1e24c24a41d90457688b436463d7595c4dd483671b1d5297518d2);
    merkle_proof.append(0x14eb21a8e98fbd61f20d0bbdba2b32cb2bcb61082dfcf5229370aca5b2dbd2);
    merkle_proof.append(0x73a5b6ab2f3ed2647ed316e5d4acac4db4b5f8da8f6e4707e633ebe02006043);
    merkle_proof.append(0x1c156b5dedc44a27e73968ebe3d464538d7bb0332f1c8191b2eb4a5afca8c7a);
    merkle_proof.append(0x39b52ee5f605f57cc893d398b09cb558c87ec9c956e11cd066df82e1006b33b);
    merkle_proof.append(0x698ea138d770764c65cb171627c57ebc1efb7c495b2c7098872cb485fd2e0bc);
    merkle_proof.append(0x313f2d7dc97dabc9a7fea0b42a5357787cabe78cdcca0d8274eabe170aaa79d);
    merkle_proof.append(0x6b35594ee638d1baa9932b306753fbd43a300435af0d51abd3dd7bd06159e80);
    merkle_proof.append(0x6e9f8a80ebebac7ba997448a1c50cd093e1b9c858cac81537446bafa4aa9431);
    merkle_proof.append(0x3082dc1a8f44267c1b9bea29a3df4bd421e9c33ee1594bf297a94dfd34c7ae4);
    // We omit the last part of the proof
    // merkle_proof.append(0x16356d27fc23e31a3570926c593bb37430201f51282f2628780264d3a399867);

    let update_data: OptionsFeedData = OptionsFeedData {
        instrument_name: 'BTC-16AUG24-52000-P',
        base_currency_id: 'BTC',
        current_timestamp: 1722805873,
        mark_price: 45431835920,
    };

    let leaf = summary_stats.get_options_data_hash(update_data);

    summary_stats.update_options_data(merkle_proof.span(), update_data);
}
