#[starknet::contract]
mod Oracle {
    use alexandria_data_structures::span_ext::SpanTraitExt;
    use core::{num::traits::Zero, cmp::{min}};
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::{UpgradeableComponent, interface::IUpgradeable};
    use pragma_entry::entry::Entry;
    use pragma_entry::structures::{
        DataType, PragmaPricesResponse, AggregationMode, PossibleEntries, Checkpoint, Currency,
        Pair, SimpleDataType, EntryStorage, SpotEntry, FutureEntry, ArrayEntry, GenericEntry,
        GenericEntryStorage, USD_CURRENCY_ID, BaseEntry, SPOT, FUTURE, GENERIC, HasPrice,
        HasBaseEntry
    };
    use pragma_oracle::utils::convert::{convert_via_usd, normalize_to_decimals};

    use pragma_oracle::{types::OracleTypes, interface::{IOracleABI}, errors::OracleErrors};
    use pragma_publisher_registry::{
        interface::{IPublisherRegistryABIDispatcher, IPublisherRegistryABIDispatcherTrait},
        errors::PublisherErrors
    };
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map, Vec, VecTrait,
        MutableVecTrait,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, ClassHash};


    // ================== COMPONENTS ==================

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;


    // ================== TYPES & CONSTANTS ==================

    const BACKWARD_TIMESTAMP_BUFFER: u64 = 3600; // 1 hour
    const FORWARD_TIMESTAMP_BUFFER: u64 = 420; // 7 minutes


    // ================== STORAGE ==================
    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        // oracle publisher registry address, ContractAddres
        oracle_publisher_registry_address_storage: ContractAddress,
        //oracle pair storage, legacy map between the pair_id and the pair in question (no need to
        //specify the data type here).
        oracle_pairs_storage: Map<OracleTypes::PairId, Pair>,
        //oracle_pair_id_storage, legacy Map between (quote_currency_id, base_currency_id) and the
        //pair_id
        oracle_pair_id_storage: Map<OracleTypes::CurrencySet, felt252>,
        //oracle_currencies_storage, legacy Map between (currency_id) and the currency
        oracle_currencies_storage: Map<OracleTypes::CurrencyId, Currency>,
        //oralce_sources_storage, Map between (pair_id ,(SPOT/FUTURES/OPTIONS/GENERIC), index,
        //expiration_timestamp ) and the source
        oracle_sources_storage: Map::<(felt252, felt252, u64, u64), felt252>,
        //oracle_sources_len_storage, Map between (pair_id ,(SPOT/FUTURES/OPTIONS/GENERIC),
        //expiration_timestamp) and the len of the sources array
        oracle_sources_len_storage: Map::<(felt252, felt252, u64), u64>,
        //oracle_publisher_storage, Map between (pair_id, (SPOT/FUTURES/OPTIONS/GENERIC),
        //index, expiration_timestamp) and the publisher
        oracle_publishers_storage: Map::<(felt252, felt252, u64, u64), felt252>,
        //oracle_publisher_len_storage, Map between (pair_id, (SPOT/FUTURES/OPTIONS/GENERIC),
        //expiration_timestamp) and the len of the publisher array
        oracle_publishers_len_storage: Map::<(felt252, felt252, u64), u64>,
        //oracle_data_entry_storage, Map between (pair_id, (SPOT/FUTURES/OPTIONS/GENERIC),
        //source, publisher, expiration_timestamp (0 for SPOT))
        oracle_data_entry_storage: Map::<(felt252, felt252, felt252, felt252, u64), EntryStorage>,
        //oracle_data_entry_storage, Map between (pair_id, source, publisher)
        oracle_data_generic_entry_storage: Map::<(felt252, felt252, felt252), GenericEntryStorage>,
        //oracle_list_of_publishers_for_sources_storage, Map between
        //(source,(SPOT/FUTURES/OPTIONS/GENERIC), and the pair_id) and the list of publishers
        oracle_list_of_publishers_for_sources_storage: Map::<
            (felt252, felt252, felt252), Vec<felt252>
        >,
        //oracle_data_entry_storage len , Map between pair_id, (SPOT/FUTURES/OPTIONS/GENERIC),
        //expiration_timestamp and the length
        oracle_data_len_all_sources: Map::<(felt252, felt252, u64), bool>,
        //oracle_checkpoints, Map between, (pair_id, (SPOT/FUTURES/OPTIONS), index,
        //expiration_timestamp (0 for SPOT), aggregation_mode) associated to a checkpoint
        oracle_checkpoints: Map::<(felt252, felt252, u64, u64, u8), Checkpoint>,
        //oracle_checkpoint_index, Map between (pair_id, (SPOT/FUTURES/OPTIONS),
        //expiration_timestamp (0 for SPOT)) and the index of the last checkpoint
        oracle_checkpoint_index: Map::<(felt252, felt252, u64, u8), u64>,
        oracle_sources_threshold_storage: u32,
    }


    // impl TupleSize5LegacyHash<
    //     E0,
    //     E1,
    //     E2,
    //     E3,
    //     E4,
    //     impl E0LegacyHash: LegacyHash<E0>,
    //     impl E1LegacyHash: LegacyHash<E1>,
    //     impl E2LegacyHash: LegacyHash<E2>,
    //     impl E3LegacyHash: LegacyHash<E3>,
    //     impl E4LegacyHash: LegacyHash<E4>,
    //     impl E0Drop: Drop<E0>,
    //     impl E1Drop: Drop<E1>,
    //     impl E2Drop: Drop<E2>,
    //     impl E3Drop: Drop<E3>,
    //     impl E4Drop: Drop<E4>,
    // > of LegacyHash<(E0, E1, E2, E3, E4)> {
    //     fn hash(state: felt252, value: (E0, E1, E2, E3, E4)) -> felt252 {
    //         let (e0, e1, e2, e3, e4) = value;
    //         let state = E0LegacyHash::hash(state, e0);
    //         let state = E1LegacyHash::hash(state, e1);
    //         let state = E2LegacyHash::hash(state, e2);
    //         let state = E3LegacyHash::hash(state, e3);
    //         E4LegacyHash::hash(state, e4)
    //     }
    // }

    #[derive(Drop, starknet::Event)]
    struct UpdatedPublisherRegistryAddress {
        old_publisher_registry_address: ContractAddress,
        new_publisher_registry_address: ContractAddress
    }


    #[derive(Drop, starknet::Event)]
    struct SubmittedSpotEntry {
        spot_entry: SpotEntry
    }


    #[derive(Drop, starknet::Event)]
    struct SubmittedFutureEntry {
        future_entry: FutureEntry
    }


    #[derive(Drop, starknet::Event)]
    struct SubmittedGenericEntry {
        generic_entry: GenericEntry
    }


    #[derive(Drop, starknet::Event)]
    struct SubmittedCurrency {
        currency: Currency
    }


    #[derive(Drop, starknet::Event)]
    struct UpdatedCurrency {
        currency: Currency
    }

    #[derive(Drop, starknet::Event)]
    struct UpdatedPair {
        pair: Pair
    }

    #[derive(Drop, starknet::Event)]
    struct SubmittedPair {
        pair: Pair
    }
    #[derive(Drop, starknet::Event)]
    struct ChangedAdmin {
        new_admin: ContractAddress
    }


    #[derive(Drop, starknet::Event)]
    struct CheckpointSpotEntry {
        pair_id: felt252,
        checkpoint: Checkpoint
    }

    #[derive(Drop, starknet::Event)]
    struct CheckpointFutureEntry {
        pair_id: felt252,
        expiration_timestamp: u64,
        checkpoint: Checkpoint
    }
    #[derive(Drop, starknet::Event)]
    #[event]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        UpdatedPublisherRegistryAddress: UpdatedPublisherRegistryAddress,
        SubmittedSpotEntry: SubmittedSpotEntry,
        SubmittedFutureEntry: SubmittedFutureEntry,
        SubmittedGenericEntry: SubmittedGenericEntry,
        SubmittedCurrency: SubmittedCurrency,
        UpdatedCurrency: UpdatedCurrency,
        UpdatedPair: UpdatedPair,
        SubmittedPair: SubmittedPair,
        CheckpointSpotEntry: CheckpointSpotEntry,
        CheckpointFutureEntry: CheckpointFutureEntry,
        ChangedAdmin: ChangedAdmin
    }

    // ================== CONSTRUCTOR ==================
    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin_address: ContractAddress,
        publisher_registry_address: ContractAddress,
        currencies: Span<Currency>,
        pairs: Span<Pair>
    ) {
        // [Check]
        assert(!admin_address.is_zero(), OracleErrors::OWNER_IS_ZERO);
        assert(!publisher_registry_address.is_zero(), OracleErrors::PUBLISHER_REGISTRY_IS_ZERO);
        // [Effect]
        self.ownable.initializer(admin_address);
        self.oracle_publisher_registry_address_storage.write(publisher_registry_address);
        self._set_keys_currencies(currencies);
        self._set_keys_pairs(pairs);
        return ();
    }

    #[abi(embed_v0)]
    impl IOracleImpl of IOracleABI<ContractState> {
        //
        // Getters
        //

        // @notice get all the data entries for given sources
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param sources : a span of sources, if no sources are provided, all the sources will be
        // considered.
        // @returns a span of PossibleEntries, which can be spot entries, future entries, generic
        // entries ...
        // @returns the last updated timestamp
        fn get_data_entries_for_sources(
            self: @ContractState, data_type: DataType, sources: Span<felt252>,
        ) -> (Span<PossibleEntries>, u64) {
            if (sources.len() == 0) {
                let all_sources = self.get_all_sources(data_type);
                let last_updated_timestamp = self
                    .get_latest_entry_timestamp(data_type, all_sources,);
                let current_timestamp: u64 = get_block_timestamp();
                let conservative_current_timestamp = min(last_updated_timestamp, current_timestamp);
                let (entries, _) = self
                    .get_all_entries(data_type, all_sources, conservative_current_timestamp);
                return (entries.span(), conservative_current_timestamp);
            } else {
                let last_updated_timestamp = self.get_latest_entry_timestamp(data_type, sources);
                let current_timestamp: u64 = get_block_timestamp();
                let conservative_current_timestamp = min(last_updated_timestamp, current_timestamp);
                let (entries, _) = self
                    .get_all_entries(data_type, sources, conservative_current_timestamp);
                return (entries.span(), conservative_current_timestamp);
            }
        }

        // @notice retrieve all the data enries for a given data type ( a data type is an asset id
        // and a type)
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @returns a span of PossibleEntries, which can be spot entries, future entries, generic
        // entries...
        fn get_data_entries(self: @ContractState, data_type: DataType) -> Span<PossibleEntries> {
            let sources = self.get_all_sources(data_type);
            let (entries, _) = self.get_data_entries_for_sources(data_type, sources);
            entries
        }

        // @notice aggregate all the entries for a given data type, using MEDIAN as aggregation mode
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @returns a PragmaPricesResponse, a structure providing the main information for an asset
        // (see entry/structs for details)
        fn get_data_median(self: @ContractState, data_type: DataType) -> PragmaPricesResponse {
            let sources = self.get_all_sources(data_type);
            let prices_response: PragmaPricesResponse = self
                .get_data_for_sources(data_type, AggregationMode::Median(()), sources);
            prices_response
        }

        // @notice aggregate the entries for specific sources,  for a given data type, using MEDIAN
        // as aggregation mode @param data_type: an enum of DataType (e.g :
        // DataType::SpotEntry(ASSET_ID) or DataType::FutureEntry((ASSSET_ID,
        // expiration_timestamp)))
        // @params sources : a span of sources used for the aggregation
        // @returns a PragmaPricesResponse, a structure providing the main information for an asset
        // (see entry/structs for details)
        fn get_data_median_for_sources(
            self: @ContractState, data_type: DataType, sources: Span<felt252>
        ) -> PragmaPricesResponse {
            let prices_response: PragmaPricesResponse = self
                .get_data_for_sources(data_type, AggregationMode::Median(()), sources,);
            prices_response
        }

        // @notice aggregate the entries for specific sources, for multiple  data type, using MEDIAN
        // as aggregation mode @param data_type: an span of DataType
        // @params sources : a span of sources used for the aggregation
        // @returns a span of PragmaPricesResponse, a structure providing the main information for
        // each asset (see entry/structs for details)
        fn get_data_median_multi(
            self: @ContractState, data_types: Span<DataType>, sources: Span<felt252>
        ) -> Span<PragmaPricesResponse> {
            let mut prices_response = ArrayTrait::<PragmaPricesResponse>::new();
            for i in 0
                ..data_types
                    .len() {
                        let data_type = *data_types.at(i);
                        let cur_prices_response: PragmaPricesResponse = self
                            .get_data_for_sources(data_type, AggregationMode::Median(()), sources);
                        prices_response.append(cur_prices_response);
                    };
            prices_response.span()
        }

        // @notice aggregate all the entries for a given data type, with a given aggregation mode
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param aggregation_mode: the aggregation method to be used (e.g.
        // AggregationMode::Median(()))
        // @returns a PragmaPricesResponse, a structure providing the main information for an asset
        // (see entry/structs for details)
        fn get_data(
            self: @ContractState, data_type: DataType, aggregation_mode: AggregationMode
        ) -> PragmaPricesResponse {
            let sources = self.get_all_sources(data_type);
            let prices_response: PragmaPricesResponse = self
                .get_data_for_sources(data_type, aggregation_mode, sources);

            prices_response
        }

        // @notice aggregate all the entries for a given data type and given sources, with a given
        // aggregation mode @param data_type: an enum of DataType (e.g :
        // DataType::SpotEntry(ASSET_ID) or DataType::FutureEntry((ASSSET_ID,
        // expiration_timestamp)))
        // @param aggregation_mode: the aggregation method to be used (e.g.
        // AggregationMode::Median(()))
        // @params sources : a span of sources used for the aggregation
        // @returns a PragmaPricesResponse, a structure providing the main information for an asset
        // (see entry/structs for details)
        fn get_data_for_sources(
            self: @ContractState,
            data_type: DataType,
            aggregation_mode: AggregationMode,
            sources: Span<felt252>
        ) -> PragmaPricesResponse {
            let (entries, _) = self.get_data_entries_for_sources(data_type, sources);
            if (entries.len() == 0) {
                return Default::default();
            }
            let mut data_sources = get_sources_from_entries(entries);
            // TODO: Return only array instead of `ArrayEntry`
            let filtered_entries: ArrayEntry = filter_data_array(data_type, entries);

            let mut response_array = ArrayTrait::<PragmaPricesResponse>::new();
            match data_type {
                DataType::SpotEntry(pair_id) => {
                    match filtered_entries {
                        ArrayEntry::SpotEntry(array_spot) => {
                            for cur_idx in 0
                                ..data_sources
                                    .len() {
                                        let source = *data_sources.get(cur_idx).unwrap().unbox();
                                        let filtered_data = self
                                            .filter_array_by_source::<
                                                SpotEntry
                                            >(array_spot.span(), source, SPOT, pair_id);
                                        let response = self
                                            .compute_median_for_source::<
                                                SpotEntry
                                            >(data_type, filtered_data, aggregation_mode);
                                        response_array.append(response);
                                    };
                            let price = Entry::aggregate_entries::<
                                PragmaPricesResponse
                            >(response_array.span(), aggregation_mode);
                            let last_updated_timestamp = Entry::aggregate_timestamps_max::<
                                PragmaPricesResponse
                            >(response_array.span());
                            let decimals = self.get_decimals(data_type);
                            return PragmaPricesResponse {
                                price: price,
                                decimals: decimals,
                                last_updated_timestamp: last_updated_timestamp,
                                num_sources_aggregated: data_sources.len(),
                                expiration_timestamp: Option::Some(0),
                                // Should be None
                            };
                        },
                        _ => {
                            panic(array![OracleErrors::WRONG_DATA_TYPE]);
                            return Default::default();
                        },
                    }
                },
                DataType::FutureEntry((
                    pair_id, expiration_timestamp
                )) => {
                    match filtered_entries {
                        ArrayEntry::FutureEntry(array_future) => {
                            for cur_idx in 0
                                ..data_sources
                                    .len() {
                                        let source = *data_sources.at(cur_idx);
                                        let filtered_data = self
                                            .filter_array_by_source::<
                                                FutureEntry
                                            >(array_future.span(), source, FUTURE, pair_id);
                                        let response = self
                                            .compute_median_for_source::<
                                                FutureEntry
                                            >(data_type, filtered_data, aggregation_mode);
                                        response_array.append(response);
                                    };
                            let price = Entry::aggregate_entries::<
                                PragmaPricesResponse
                            >(response_array.span(), aggregation_mode);
                            let last_updated_timestamp = Entry::aggregate_timestamps_max::<
                                PragmaPricesResponse
                            >(response_array.span());
                            let decimals = self.get_decimals(data_type);
                            return PragmaPricesResponse {
                                price: price,
                                decimals: decimals,
                                last_updated_timestamp: last_updated_timestamp,
                                num_sources_aggregated: data_sources.len(),
                                expiration_timestamp: Option::Some(expiration_timestamp),
                                // Should be None
                            };
                        },
                        _ => {
                            panic(array![OracleErrors::WRONG_DATA_TYPE]);
                            return Default::default();
                        }
                    }
                },
                DataType::GenericEntry(key) => {
                    match filtered_entries {
                        ArrayEntry::GenericEntry(array_generic) => {
                            for cur_idx in 0
                                ..data_sources
                                    .len() {
                                        let source = *data_sources.at(cur_idx);
                                        let filtered_data = self
                                            .filter_array_by_source::<
                                                GenericEntry
                                            >(array_generic.span(), source, GENERIC, key);
                                        let response = self
                                            .compute_median_for_source::<
                                                GenericEntry
                                            >(data_type, filtered_data, aggregation_mode);
                                        response_array.append(response);
                                    };
                            let price = Entry::aggregate_entries::<
                                PragmaPricesResponse
                            >(response_array.span(), aggregation_mode);
                            let last_updated_timestamp = Entry::aggregate_timestamps_max::<
                                PragmaPricesResponse
                            >(response_array.span());
                            let decimals = self.get_decimals(data_type);
                            return PragmaPricesResponse {
                                price: price,
                                decimals: decimals,
                                last_updated_timestamp: last_updated_timestamp,
                                num_sources_aggregated: data_sources.len(),
                                expiration_timestamp: Option::Some(0),
                                // Should be None
                            };
                        },
                        _ => {
                            panic(array![OracleErrors::WRONG_DATA_TYPE]);
                            return Default::default();
                        },
                    }
                },
            }
        }

        // @notice get the publisher registry address associated with the oracle
        // @returns the linked publisher registry address
        fn get_publisher_registry_address(self: @ContractState) -> ContractAddress {
            self.oracle_publisher_registry_address_storage.read()
        }

        // @notice retrieve the precision (number of decimals) for a pair
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @returns the precision for the given data type
        fn get_decimals(self: @ContractState, data_type: DataType) -> u32 {
            let (base_currency, quote_currency) = match data_type {
                DataType::SpotEntry(pair_id) => {
                    let pair = self.oracle_pairs_storage.entry(pair_id).read();
                    assert(!pair.id.is_zero(), OracleErrors::NO_PAIR_RECORDED);
                    let base_cur = self
                        .oracle_currencies_storage
                        .entry(pair.base_currency_id)
                        .read();
                    let quote_cur = self
                        .oracle_currencies_storage
                        .entry(pair.quote_currency_id)
                        .read();
                    (base_cur, quote_cur)
                },
                DataType::FutureEntry((
                    pair_id, _
                )) => {
                    let pair = self.oracle_pairs_storage.entry(pair_id).read();
                    assert(!pair.id.is_zero(), OracleErrors::NO_PAIR_RECORDED);
                    let base_cur = self
                        .oracle_currencies_storage
                        .entry(pair.base_currency_id)
                        .read();
                    let quote_cur = self
                        .oracle_currencies_storage
                        .entry(pair.quote_currency_id)
                        .read();
                    (base_cur, quote_cur)
                },
                DataType::GenericEntry(key) => {
                    let pair = self.oracle_pairs_storage.entry(key).read();
                    assert(!pair.id.is_zero(), OracleErrors::NO_PAIR_RECORDED);
                    let base_cur = self
                        .oracle_currencies_storage
                        .entry(pair.base_currency_id)
                        .read();
                    let quote_cur = self
                        .oracle_currencies_storage
                        .entry(pair.quote_currency_id)
                        .read();
                    (base_cur, quote_cur)
                }
                // DataType::OptionEntry((pair_id, expiration_timestamp)) => {}
            };
            min(base_currency.decimals, quote_currency.decimals)
        }

        // @notice aggregate entries information using an USD hop (BTC/ETH => BTC/USD + ETH/USD)
        // @param base_currency_id: the pragma key for the base currency
        // @param quote_currency_id : the pragma key for the quote currency id
        // @param aggregation_mode :the aggregation method to be used (e.g.
        // AggregationMode::Median(()))
        // @param typeof : the type of data to work with ( Spot, Future, ...)
        // @param expiration_timestamp : optional, for futures
        // @returns a PragmaPricesResponse, a structure providing the main information for an asset
        // (see entry/structs for details)
        fn get_data_with_USD_hop(
            self: @ContractState,
            base_currency_id: felt252,
            quote_currency_id: felt252,
            aggregation_mode: AggregationMode,
            typeof: SimpleDataType,
            expiration_timestamp: Option<u64>
        ) -> PragmaPricesResponse {
            let mut sources = ArrayTrait::<felt252>::new().span();
            let base_pair_id = self
                .oracle_pair_id_storage
                .entry((base_currency_id, USD_CURRENCY_ID))
                .read();
            assert(base_pair_id != 0, OracleErrors::NO_PAIR_RECORDED);
            let quote_pair_id = self
                .oracle_pair_id_storage
                .entry((quote_currency_id, USD_CURRENCY_ID))
                .read();
            assert(quote_pair_id != 0, OracleErrors::NO_PAIR_RECORDED);
            let (base_data_type, quote_data_type, _) = match typeof {
                SimpleDataType::SpotEntry(()) => {
                    (
                        DataType::SpotEntry(base_pair_id),
                        DataType::SpotEntry(quote_pair_id),
                        self.oracle_currencies_storage.entry(quote_currency_id).read()
                    )
                },
                SimpleDataType::FutureEntry(()) => {
                    match expiration_timestamp {
                        Option::Some(expiration) => {
                            (
                                DataType::FutureEntry((base_pair_id, expiration)),
                                DataType::FutureEntry((quote_pair_id, expiration)),
                                self.oracle_currencies_storage.entry(quote_currency_id).read()
                            )
                        },
                        Option::None(_) => {
                            // Handle case where Future data type was provided without an expiration
                            // timestamp
                            panic(array![OracleErrors::EXPIRATION_TIMESTAMP_IS_REQUIRED]);
                            (
                                DataType::FutureEntry((base_pair_id, 0)),
                                DataType::FutureEntry((quote_pair_id, 0)),
                                self.oracle_currencies_storage.entry(quote_currency_id).read()
                            )
                        }
                    }
                },
            };
            let basePPR: PragmaPricesResponse = self
                .get_data_for_sources(base_data_type, aggregation_mode, sources);

            let quotePPR: PragmaPricesResponse = self
                .get_data_for_sources(quote_data_type, aggregation_mode, sources);

            let quote_decimals = self.get_decimals(quote_data_type);
            let base_decimals = self.get_decimals(base_data_type);
            let (rebased_value, decimals) = if (base_decimals < quote_decimals) {
                let normalised_basePPR_price = normalize_to_decimals(
                    basePPR.price, self.get_decimals(base_data_type), quote_decimals
                );
                (
                    convert_via_usd(normalised_basePPR_price, quotePPR.price, quote_decimals),
                    quote_decimals
                )
            } else {
                let normalised_quotePPR_price = normalize_to_decimals(
                    quotePPR.price, self.get_decimals(quote_data_type), base_decimals
                );
                (
                    convert_via_usd(basePPR.price, normalised_quotePPR_price, base_decimals),
                    base_decimals
                )
            };

            let last_updated_timestamp = min(
                quotePPR.last_updated_timestamp, basePPR.last_updated_timestamp
            );
            let num_sources_aggregated = min(
                quotePPR.num_sources_aggregated, basePPR.num_sources_aggregated
            );
            PragmaPricesResponse {
                price: rebased_value,
                decimals: decimals,
                last_updated_timestamp: last_updated_timestamp,
                num_sources_aggregated: num_sources_aggregated,
                expiration_timestamp: expiration_timestamp,
            }
        }

        // @notice get the last checkpoint index (a checkpoint is a 'save' of the oracle information
        // used for summary stats computations -realised volatility, twap, mean...)
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param aggregation_mode: the aggregation method to be used
        // @returns last checkpoint index
        // @returns a boolean to verify if a checkpoint is actually set (case 0)
        fn get_latest_checkpoint_index(
            self: @ContractState, data_type: DataType, aggregation_mode: AggregationMode
        ) -> (u64, bool) {
            self._get_latest_checkpoint_index(data_type, aggregation_mode)
        }

        // @notice get the latest checkpoint recorded
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param aggregation_mode: the aggregation method to be used
        // @returns the latest checkpoint (see entry/structs for the structure details)
        fn get_latest_checkpoint(
            self: @ContractState, data_type: DataType, aggregation_mode: AggregationMode
        ) -> Checkpoint {
            let (checkpoint_index, is_valid) = self
                ._get_latest_checkpoint_index(data_type, aggregation_mode);
            if (!is_valid) {
                Checkpoint {
                    timestamp: 0,
                    value: 0,
                    aggregation_mode: aggregation_mode,
                    num_sources_aggregated: 0,
                }
            } else {
                self.get_checkpoint_by_index(data_type, checkpoint_index, aggregation_mode)
            }
        }

        // @notice retrieve a specific checkpoint by its index
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param checkpoint_index: the index of the checkpoint to be considered
        // @param aggregation_mode: the aggregation method to be used
        // @returns the checkpoint related
        fn get_checkpoint(
            self: @ContractState,
            data_type: DataType,
            checkpoint_index: u64,
            aggregation_mode: AggregationMode
        ) -> Checkpoint {
            self.get_checkpoint_by_index(data_type, checkpoint_index, aggregation_mode)
        }


        fn get_sources_threshold(self: @ContractState) -> u32 {
            self.oracle_sources_threshold_storage.read()
        }

        // @notice retrieve the last checkpoint before a given timestamp
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param timestamp : the timestamp to consider
        // @param aggregation_mode: the aggregation method to be used
        // @returns the checkpoint
        // @returns the index related to the checkpoint
        fn get_last_checkpoint_before(
            self: @ContractState,
            data_type: DataType,
            timestamp: u64,
            aggregation_mode: AggregationMode,
        ) -> (Checkpoint, u64) {
            let idx = self.find_startpoint(data_type, aggregation_mode, timestamp);

            let checkpoint = self.get_checkpoint_by_index(data_type, idx, aggregation_mode);

            (checkpoint, idx)
        }

        // @notice get the data entry for a given data type and a source
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param source: the source to retrieve the entry from
        // @returns a PossibleEntries, linked to the type of data needed (Spot, futures, generic,
        // ...)
        fn get_data_entry(
            self: @ContractState, data_type: DataType, source: felt252, publisher: felt252
        ) -> PossibleEntries {
            let result = match data_type {
                DataType::SpotEntry(pair_id) => {
                    let _entry = self.get_entry_storage(pair_id, SPOT, source, publisher, 0);
                    assert(!_entry.timestamp.is_zero(), OracleErrors::NO_DATA_ENTRY_FOUND);
                    PossibleEntries::Spot(
                        SpotEntry {
                            base: BaseEntry {
                                timestamp: _entry.timestamp, source: source, publisher: publisher
                            },
                            pair_id: pair_id,
                            price: _entry.price,
                            volume: _entry.volume
                        }
                    )
                },
                DataType::FutureEntry((
                    pair_id, expiration_timestamp
                )) => {
                    let _entry = self
                        .get_entry_storage(
                            pair_id, FUTURE, source, publisher, expiration_timestamp
                        );
                    assert(!_entry.timestamp.is_zero(), OracleErrors::NO_DATA_ENTRY_FOUND);
                    PossibleEntries::Future(
                        FutureEntry {
                            base: BaseEntry {
                                timestamp: _entry.timestamp, source: source, publisher: publisher
                            },
                            pair_id: pair_id,
                            price: _entry.price,
                            volume: _entry.volume,
                            expiration_timestamp: expiration_timestamp
                        }
                    )
                },
                DataType::GenericEntry(key) => {
                    let _entry = self.get_generic_entry_storage(key, source, publisher);
                    assert(!_entry.timestamp.is_zero(), OracleErrors::NO_DATA_ENTRY_FOUND);
                    PossibleEntries::Generic(
                        GenericEntry {
                            base: BaseEntry {
                                timestamp: _entry.timestamp, source: source, publisher: publisher
                            },
                            key: key,
                            value: _entry.value
                        }
                    )
                }
            };

            result
        }

        // @notice get the data entry for a given data type and a source (realise a median of the
        // publishers for the source)
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID))
        // @param source: the source to retrieve the entry from
        // @returns a PossibleEntries, linked to the type of data needed (Spot, futures, generic,
        // ...)
        fn get_data_entry_for_publishers(
            self: @ContractState, data_type: DataType, source: felt252
        ) -> PossibleEntries {
            let mut cur_idx = 0;
            let mut volumes = ArrayTrait::<u128>::new();
            match data_type {
                DataType::SpotEntry(pair_id) => {
                    let publishers = self.get_publishers_for_source(source, SPOT, pair_id);
                    let mut spot_entries = ArrayTrait::<SpotEntry>::new();
                    loop {
                        if (cur_idx == publishers.len()) {
                            break ();
                        }
                        let publisher = *publishers.at(cur_idx);
                        let entry = self.get_data_entry(data_type, source, publisher);
                        match entry {
                            PossibleEntries::Spot(spot_entry) => {
                                spot_entries.append(spot_entry);
                                volumes.append(spot_entry.volume);
                            },
                            PossibleEntries::Future(_) => {},
                            PossibleEntries::Generic(_) => {},
                        }
                        cur_idx += 1;
                    };
                    let median = Entry::aggregate_entries::<
                        SpotEntry
                    >(spot_entries.span(), AggregationMode::Median(()));
                    let median_volume = Entry::compute_median(volumes);
                    let last_updated_timestamp = Entry::aggregate_timestamps_max::<
                        SpotEntry
                    >(spot_entries.span());
                    return PossibleEntries::Spot(
                        SpotEntry {
                            base: BaseEntry {
                                timestamp: last_updated_timestamp, source: source, publisher: 0
                            },
                            pair_id: pair_id,
                            price: median,
                            volume: median_volume
                        }
                    );
                },
                DataType::FutureEntry((
                    pair_id, expiration_timestamp
                )) => {
                    let mut future_entries = ArrayTrait::<FutureEntry>::new();
                    let publishers = self.get_publishers_for_source(source, FUTURE, pair_id);

                    loop {
                        if (cur_idx == publishers.len()) {
                            break ();
                        }
                        let publisher = *publishers.at(cur_idx);
                        let entry = self.get_data_entry(data_type, source, publisher);
                        match entry {
                            PossibleEntries::Spot(_) => {},
                            PossibleEntries::Future(future_entry) => {
                                future_entries.append(future_entry);
                                volumes.append(future_entry.volume);
                            },
                            PossibleEntries::Generic(_) => {},
                        }
                        cur_idx += 1;
                    };
                    let median = Entry::aggregate_entries::<
                        FutureEntry
                    >(future_entries.span(), AggregationMode::Median(()));
                    let median_volume = Entry::compute_median(volumes);

                    let last_updated_timestamp = Entry::aggregate_timestamps_max::<
                        FutureEntry
                    >(future_entries.span());
                    return PossibleEntries::Future(
                        FutureEntry {
                            base: BaseEntry {
                                timestamp: last_updated_timestamp, source: source, publisher: 0
                            },
                            pair_id: pair_id,
                            price: median,
                            volume: median_volume,
                            expiration_timestamp: expiration_timestamp
                        }
                    );
                },
                DataType::GenericEntry(key) => {
                    let publishers = self.get_publishers_for_source(source, GENERIC, key);

                    let mut generic_entries = ArrayTrait::<GenericEntry>::new();
                    loop {
                        if (cur_idx == publishers.len()) {
                            break ();
                        }
                        let publisher = *publishers.at(cur_idx);
                        let entry = IOracleABI::get_data_entry(self, data_type, source, publisher);
                        match entry {
                            PossibleEntries::Spot(_) => {},
                            PossibleEntries::Future(_) => {},
                            PossibleEntries::Generic(generic_entry) => {
                                generic_entries.append(generic_entry);
                            },
                        }
                        cur_idx += 1;
                    };
                    let median = Entry::aggregate_entries::<
                        GenericEntry
                    >(generic_entries.span(), AggregationMode::Median(()));
                    let last_updated_timestamp = Entry::aggregate_timestamps_max::<
                        GenericEntry
                    >(generic_entries.span());
                    return PossibleEntries::Generic(
                        GenericEntry {
                            base: BaseEntry {
                                timestamp: last_updated_timestamp, source: source, publisher: 0
                            },
                            key: key,
                            value: median.into()
                        }
                    );
                }
            }
        }
        //
        // Setters
        //

        // @notice publish oracle data on chain
        // @notice in order to publish, the publisher must be registered for the specific
        // source/asset.
        // @param new_entry, the new entry that needs to be published
        fn publish_data(ref self: ContractState, new_entry: PossibleEntries) {
            match new_entry {
                PossibleEntries::Spot(spot_entry) => {
                    self.validate_sender_for_source(spot_entry);
                    let res = self
                        .get_entry_storage(
                            spot_entry.pair_id,
                            SPOT,
                            spot_entry.base.source,
                            spot_entry.base.publisher,
                            0
                        );
                    if (res.timestamp != 0) {
                        let entry: PossibleEntries = IOracleABI::get_data_entry(
                            @self,
                            DataType::SpotEntry(spot_entry.pair_id),
                            spot_entry.base.source,
                            spot_entry.base.publisher
                        );
                        match entry {
                            PossibleEntries::Spot(spot) => {
                                self.validate_data_timestamp(new_entry, spot);
                            },
                            PossibleEntries::Future(_) => {},
                            PossibleEntries::Generic(_) => {},
                        }
                    } else {
                        let mut publishers_list = self
                            .get_publishers_for_source(
                                spot_entry.base.source, SPOT, spot_entry.pair_id
                            );
                        if (publishers_list.len() == 0) {
                            let sources_len = self
                                .oracle_sources_len_storage
                                .entry((spot_entry.pair_id, SPOT, 0))
                                .read();
                            self
                                .oracle_sources_storage
                                .entry((spot_entry.pair_id, SPOT, sources_len, 0))
                                .write(spot_entry.get_base_entry().source);
                            self
                                .oracle_sources_len_storage
                                .entry((spot_entry.pair_id, SPOT, 0))
                                .write(sources_len + 1);
                        }
                        let all_publishers = IOracleABI::get_all_publishers(
                            @self, DataType::SpotEntry(spot_entry.pair_id)
                        );
                        if (!all_publishers.contains(@spot_entry.base.publisher)) {
                            let publisher_len = self
                                .oracle_publishers_len_storage
                                .entry((spot_entry.pair_id, SPOT, 0))
                                .read();
                            self
                                .oracle_publishers_storage
                                .entry((spot_entry.pair_id, SPOT, publisher_len, 0))
                                .write(spot_entry.get_base_entry().publisher);
                            self
                                .oracle_publishers_len_storage
                                .entry((spot_entry.pair_id, SPOT, 0))
                                .write(publisher_len + 1);
                        }
                        if (!publishers_list.contains(@spot_entry.base.publisher)) {
                            self
                                .oracle_list_of_publishers_for_sources_storage
                                .entry((spot_entry.base.source, SPOT, spot_entry.pair_id))
                                .append()
                                .write(spot_entry.base.publisher);
                        }
                    }
                    self.emit(Event::SubmittedSpotEntry(SubmittedSpotEntry { spot_entry }));
                    let element = EntryStorage {
                        timestamp: spot_entry.base.timestamp,
                        volume: spot_entry.volume,
                        price: spot_entry.price
                    };
                    self
                        .set_entry_storage(
                            spot_entry.pair_id,
                            SPOT,
                            spot_entry.base.source,
                            spot_entry.base.publisher,
                            0,
                            element
                        );

                    let storage_len = self
                        .oracle_data_len_all_sources
                        .entry((spot_entry.pair_id, SPOT, 0))
                        .read();
                    if (!storage_len) {
                        self
                            .oracle_data_len_all_sources
                            .entry((spot_entry.pair_id, SPOT, 0))
                            .write(true);
                    }
                },
                PossibleEntries::Future(future_entry) => {
                    self.validate_sender_for_source(future_entry);
                    let res = self
                        .get_entry_storage(
                            future_entry.pair_id,
                            FUTURE,
                            future_entry.base.source,
                            future_entry.base.publisher,
                            future_entry.expiration_timestamp
                        );
                    if (res.timestamp != 0) {
                        let entry: PossibleEntries = self
                            .get_data_entry(
                                DataType::FutureEntry(
                                    (future_entry.pair_id, future_entry.expiration_timestamp)
                                ),
                                future_entry.base.source,
                                future_entry.base.publisher
                            );
                        match entry {
                            PossibleEntries::Spot(_) => {},
                            PossibleEntries::Future(future) => {
                                self.validate_data_timestamp(new_entry, future)
                            },
                            PossibleEntries::Generic(_) => {}
                        }
                    } else {
                        let mut publishers_list = self
                            .get_publishers_for_source(
                                future_entry.base.source, FUTURE, future_entry.pair_id
                            );
                        if (publishers_list.len() == 0) {
                            let sources_len = self
                                .oracle_sources_len_storage
                                .entry(
                                    (
                                        future_entry.pair_id,
                                        FUTURE,
                                        future_entry.expiration_timestamp
                                    )
                                )
                                .read();
                            self
                                .oracle_sources_storage
                                .entry(
                                    (
                                        future_entry.pair_id,
                                        FUTURE,
                                        sources_len,
                                        future_entry.expiration_timestamp
                                    )
                                )
                                .write(future_entry.get_base_entry().source);
                            self
                                .oracle_sources_len_storage
                                .entry(
                                    (
                                        future_entry.pair_id,
                                        FUTURE,
                                        future_entry.expiration_timestamp
                                    )
                                )
                                .write(sources_len + 1);
                        }
                        let all_publishers = self
                            .get_all_publishers(
                                DataType::FutureEntry(
                                    (future_entry.pair_id, future_entry.expiration_timestamp)
                                )
                            );
                        if (!all_publishers.contains(@future_entry.base.publisher)) {
                            let publisher_len = self
                                .oracle_publishers_len_storage
                                .entry(
                                    (
                                        future_entry.pair_id,
                                        FUTURE,
                                        future_entry.expiration_timestamp
                                    )
                                )
                                .read();
                            self
                                .oracle_publishers_storage
                                .entry(
                                    (
                                        future_entry.pair_id,
                                        FUTURE,
                                        publisher_len,
                                        future_entry.expiration_timestamp
                                    )
                                )
                                .write(future_entry.get_base_entry().publisher);
                            self
                                .oracle_publishers_len_storage
                                .entry(
                                    (
                                        future_entry.pair_id,
                                        FUTURE,
                                        future_entry.expiration_timestamp
                                    )
                                )
                                .write(publisher_len + 1);
                        }
                        let mut publishers_list = self
                            .get_publishers_for_source(
                                future_entry.base.source, FUTURE, future_entry.pair_id
                            );
                        if (!publishers_list.contains(@future_entry.base.publisher)) {
                            self
                                .oracle_list_of_publishers_for_sources_storage
                                .entry((future_entry.base.source, FUTURE, future_entry.pair_id))
                                .append()
                                .write(future_entry.base.publisher);
                        }
                    }

                    self.emit(Event::SubmittedFutureEntry(SubmittedFutureEntry { future_entry }));

                    let element: EntryStorage = EntryStorage {
                        timestamp: future_entry.base.timestamp,
                        volume: future_entry.volume,
                        price: future_entry.price
                    };
                    self
                        .set_entry_storage(
                            future_entry.pair_id,
                            FUTURE,
                            future_entry.base.source,
                            future_entry.base.publisher,
                            future_entry.expiration_timestamp,
                            element
                        );
                    let storage_len = self
                        .oracle_data_len_all_sources
                        .entry((future_entry.pair_id, FUTURE, future_entry.expiration_timestamp))
                        .read();
                    if (!storage_len) {
                        self
                            .oracle_data_len_all_sources
                            .entry(
                                (future_entry.pair_id, FUTURE, future_entry.expiration_timestamp)
                            )
                            .write(true);
                    }
                },
                PossibleEntries::Generic(generic_entry) => {
                    self.validate_sender_for_source(generic_entry);
                    let res = self
                        .get_generic_entry_storage(
                            generic_entry.key,
                            generic_entry.base.source,
                            generic_entry.base.publisher,
                        );

                    if (res.timestamp != 0) {
                        let entry: PossibleEntries = IOracleABI::get_data_entry(
                            @self,
                            DataType::GenericEntry(generic_entry.key),
                            generic_entry.base.source,
                            generic_entry.base.publisher
                        );

                        match entry {
                            PossibleEntries::Spot(_) => {},
                            PossibleEntries::Future(_) => {},
                            PossibleEntries::Generic(generic) => {
                                self.validate_data_timestamp(new_entry, generic)
                            }
                        }
                    } else {
                        let mut publishers_list = self
                            .get_publishers_for_source(
                                generic_entry.base.source, GENERIC, generic_entry.key
                            );
                        if (publishers_list.len() == 0) {
                            let sources_len = self
                                .oracle_sources_len_storage
                                .entry((generic_entry.key, GENERIC, 0))
                                .read();
                            self
                                .oracle_sources_storage
                                .entry((generic_entry.key, GENERIC, sources_len, 0))
                                .write(generic_entry.get_base_entry().source);
                            self
                                .oracle_sources_len_storage
                                .entry((generic_entry.key, GENERIC, 0))
                                .write(sources_len + 1);
                        }
                        let all_publishers = IOracleABI::get_all_publishers(
                            @self, DataType::GenericEntry(generic_entry.key)
                        );
                        if (!all_publishers.contains(@generic_entry.base.publisher)) {
                            let publisher_len = self
                                .oracle_publishers_len_storage
                                .entry((generic_entry.key, GENERIC, 0))
                                .read();
                            self
                                .oracle_publishers_storage
                                .entry((generic_entry.key, GENERIC, publisher_len, 0))
                                .write(generic_entry.get_base_entry().publisher);
                            self
                                .oracle_publishers_len_storage
                                .entry((generic_entry.key, GENERIC, 0))
                                .write(publisher_len + 1);
                        }
                        if (!publishers_list.contains(@generic_entry.base.publisher)) {
                            self
                                .oracle_list_of_publishers_for_sources_storage
                                .entry((generic_entry.base.source, GENERIC, generic_entry.key))
                                .append()
                                .write(generic_entry.base.publisher);
                        }
                    }
                    self
                        .emit(
                            Event::SubmittedGenericEntry(SubmittedGenericEntry { generic_entry })
                        );

                    let element = GenericEntryStorage {
                        timestamp: generic_entry.base.timestamp, value: generic_entry.value,
                    };

                    self
                        .set_generic_entry_storage(
                            generic_entry.key,
                            generic_entry.base.source,
                            generic_entry.base.publisher,
                            element
                        );

                    let storage_len = self
                        .oracle_data_len_all_sources
                        .entry((generic_entry.key, GENERIC, 0))
                        .read();
                    if (!storage_len) {
                        self
                            .oracle_data_len_all_sources
                            .entry((generic_entry.key, GENERIC, 0))
                            .write(true);
                    }
                }
            }

            return ();
        }

        // @notice retrieve all the available publishers for a given data type
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @returns a span of publishers
        fn get_all_publishers(self: @ContractState, data_type: DataType) -> Span<felt252> {
            let mut publishers = ArrayTrait::<felt252>::new();
            match data_type {
                DataType::SpotEntry(pair_id) => {
                    let publisher_len = self
                        .oracle_publishers_len_storage
                        .entry((pair_id, SPOT, 0))
                        .read();
                    self.build_publishers_array(data_type, ref publishers, publisher_len);
                    return publishers.span();
                },
                DataType::FutureEntry((
                    pair_id, expiration_timestamp
                )) => {
                    let publisher_len = self
                        .oracle_publishers_len_storage
                        .entry((pair_id, FUTURE, expiration_timestamp))
                        .read();
                    self.build_publishers_array(data_type, ref publishers, publisher_len);
                    return publishers.span();
                },
                DataType::GenericEntry(key) => {
                    let publisher_len = self
                        .oracle_publishers_len_storage
                        .entry((key, GENERIC, 0))
                        .read();
                    self.build_publishers_array(data_type, ref publishers, publisher_len);
                    return publishers.span();
                }
            }
        }

        // @notice retrieve all the available sources for a given data type
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @returns a span of sources
        fn get_all_sources(self: @ContractState, data_type: DataType) -> Span<felt252> {
            let mut sources = ArrayTrait::<felt252>::new();
            match data_type {
                DataType::SpotEntry(pair_id) => {
                    let source_len = self
                        .oracle_sources_len_storage
                        .entry((pair_id, SPOT, 0))
                        .read();
                    self.build_sources_array(data_type, ref sources, source_len);
                    return sources.span();
                },
                DataType::FutureEntry((
                    pair_id, expiration_timestamp
                )) => {
                    let source_len = self
                        .oracle_sources_len_storage
                        .entry((pair_id, FUTURE, expiration_timestamp))
                        .read();
                    self.build_sources_array(data_type, ref sources, source_len);

                    return sources.span();
                },
                DataType::GenericEntry(key) => {
                    let source_len = self
                        .oracle_sources_len_storage
                        .entry((key, GENERIC, 0))
                        .read();
                    self.build_sources_array(data_type, ref sources, source_len);
                    return sources.span();
                }
            }
        }

        // @notice publish oracle data on chain (multiple entries)
        // @notice in order to publish, the publisher must be registered for the specific
        // source/asset.
        // @param new_entries, span of  new entries that needs to be published
        fn publish_data_entries(ref self: ContractState, new_entries: Span<PossibleEntries>) {
            let mut cur_idx = 0;
            loop {
                if (cur_idx >= new_entries.len()) {
                    break ();
                }
                let new_entry = *new_entries.at(cur_idx);
                self.publish_data(new_entry);
                cur_idx = cur_idx + 1;
            }
        }

        // @notice update the publisher registry associated with the oracle
        // @param new_publisher_registry_address: the address of the new publisher registry
        fn update_publisher_registry_address(
            ref self: ContractState, new_publisher_registry_address: ContractAddress
        ) {
            // [Check]
            self.ownable.assert_only_owner();
            assert(
                !new_publisher_registry_address.is_zero(), OracleErrors::PUBLISHER_REGISTRY_IS_ZERO
            );
            let old_publisher_registry_address = self.get_publisher_registry_address();

            // [Effect]
            self.oracle_publisher_registry_address_storage.write(new_publisher_registry_address);

            // [Interaction]
            self
                .emit(
                    Event::UpdatedPublisherRegistryAddress(
                        UpdatedPublisherRegistryAddress {
                            old_publisher_registry_address, new_publisher_registry_address
                        }
                    )
                );
            return ();
        }

        // @notice retrieve the Currency associated to a currency id.
        // @param currency_id: The currency id to retrieve the information from
        // @returns the Currency struct associated
        fn get_currency(self: @ContractState, currency_id: felt252) -> Currency {
            self.oracle_currencies_storage.entry(currency_id).read()
        }


        // @notice retrieve the Pair associated to a pair id.
        // @param pair_id: The pair id to retrieve the information from
        // @returns the Pair struct associated
        fn get_pair(self: @ContractState, pair_id: felt252) -> Pair {
            self.oracle_pairs_storage.entry(pair_id).read()
        }


        // @notice add a new currency to the oracle (e.g ETH)
        // @dev can be called only by the admin
        // @param new_currency: the new currency to be added
        fn add_currency(ref self: ContractState, new_currency: Currency) {
            // [Check]
            self.ownable.assert_only_owner();
            assert(new_currency.id != 0, OracleErrors::CURRENCY_ID_CANNOT_BE_ZERO);
            let existing_currency = self.oracle_currencies_storage.entry(new_currency.id).read();
            assert(existing_currency.id == 0, OracleErrors::CURRENCY_ALREADY_EXISTS_FOR_KEY);

            // [Effect]
            self.oracle_currencies_storage.entry(new_currency.id).write(new_currency);

            // [Interaction]
            self.emit(Event::SubmittedCurrency(SubmittedCurrency { currency: new_currency }));
            return ();
        }

        // @notice update an existing currency
        // @dev can be called only by the admin
        // @param currency_id: the currency id to be updated
        // @param currency: the currency to be updated
        fn update_currency(ref self: ContractState, currency_id: felt252, currency: Currency) {
            // [Check]
            self.ownable.assert_only_owner();
            assert(currency_id == currency.id, OracleErrors::CURRENCY_ID_NOT_CORRESPONDING);
            let existing_currency = self.oracle_currencies_storage.entry(currency_id).read();
            assert(existing_currency.id != 0, OracleErrors::NO_CURRENCY_RECORDED);

            // [Effect]
            self.oracle_currencies_storage.entry(currency_id).write(currency);

            // [Interaction]
            self.emit(Event::UpdatedCurrency(UpdatedCurrency { currency: currency }));

            return ();
        }


        // @notice update an existing pair
        // @dev can be called only by the admin
        // @param pair_id: the Pair id to be updated
        // @param pair: the pair to be updated
        fn update_pair(ref self: ContractState, pair_id: felt252, pair: Pair) {
            // [Check]
            self.ownable.assert_only_owner();
            assert(pair_id == pair.id, OracleErrors::PAIR_ID_NOT_CORRESPONDING);
            let existing_pair = self.oracle_pairs_storage.entry(pair_id).read();
            assert(existing_pair.id != 0, OracleErrors::NO_PAIR_RECORDED);

            // [Effect]
            self.oracle_pairs_storage.entry(pair_id).write(pair);
            self
                .oracle_pair_id_storage
                .entry((pair.quote_currency_id, pair.base_currency_id))
                .write(pair.id);

            // [Interaction]
            self.emit(Event::UpdatedPair(UpdatedPair { pair: pair }));
            return ();
        }


        // @notice add a new pair to the oracle (e.g ETH)
        // @dev can be called only by the admin
        // @param new_pair: the new pair to be added
        fn add_pair(ref self: ContractState, new_pair: Pair) {
            // [Check]
            self.ownable.assert_only_owner();
            let check_pair = self.oracle_pairs_storage.entry(new_pair.id).read();
            assert(check_pair.id == 0, OracleErrors::PAIR_WITH_THIS_KEY_REGISTERED);
            assert(new_pair.id != 0, OracleErrors::PAIR_ID_CANNOT_BE_NULL);
            let base_currency = self
                .oracle_currencies_storage
                .entry(new_pair.base_currency_id)
                .read();
            assert(base_currency.id != 0, OracleErrors::NO_BASE_CURRENCY_REGISTERED);
            let quote_currency = self
                .oracle_currencies_storage
                .entry(new_pair.quote_currency_id)
                .read();
            assert(quote_currency.id != 0, OracleErrors::NO_QUOTE_CURRENCY_REGISTERED);

            // [Effect]
            self.oracle_pairs_storage.entry(new_pair.id).write(new_pair);
            self
                .oracle_pair_id_storage
                .entry((new_pair.quote_currency_id, new_pair.base_currency_id))
                .write(new_pair.id);

            // [Interaction]
            self.emit(Event::SubmittedPair(SubmittedPair { pair: new_pair }));
            return ();
        }


        // FUNCTION TEMPORARLY OFF

        // @notice remove a source for a given data type(DataType)
        // @dev can be called only by the admin
        // @dev need to also call remove_source_for_all_publishers on the publisher registry
        // contract @param source: the source to be removed
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID))
        // fn remove_source(ref self: ContractState, source: felt252, data_type: DataType) -> bool {
        //     self.ownable.assert_only_owner();
        //     match data_type {
        //         DataType::SpotEntry(pair_id) => {
        //             let sources_len = self
        //                 .oracle_sources_len_storage
        //                 .entry((pair_id, SPOT, 0))
        //                 .read();
        //             let mut cur_idx = 0;
        //             let is_in_storage: bool = loop {
        //                 if (cur_idx == sources_len) {
        //                     break false;
        //                 }
        //                 let cur_source = self
        //                     .oracle_sources_storage
        //                     .entry((pair_id, SPOT, cur_idx, 0))
        //                     .read();
        //                 if (source == cur_source) {
        //                     break true;
        //                 }
        //                 cur_idx += 1;
        //             };
        //             if (!is_in_storage) {
        //                 panic(array![OracleErrors::SOURCE_NOT_FOUND]);
        //             }
        //             if (cur_idx == sources_len - 1) {
        //                 self
        //                     .oracle_sources_len_storage
        //                     .entry((pair_id, SPOT, 0))
        //                     .write(sources_len - 1);
        //                 self
        //                     .oracle_sources_storage
        //                     .entry((pair_id, SPOT, sources_len - 1, 0))
        //                     .write(0);
        //             } else {
        //                 let last_source = self
        //                     .oracle_sources_storage
        //                     .entry((pair_id, SPOT, sources_len - 1, 0))
        //                     .read();
        //                 self
        //                     .oracle_sources_storage
        //                     .entry((pair_id, SPOT, cur_idx, 0))
        //                     .write(last_source);
        //                 self
        //                     .oracle_sources_storage
        //                     .entry((pair_id, SPOT, sources_len - 1, 0))
        //                     .write(0);
        //                 self
        //                     .oracle_sources_len_storage
        //                     .entry((pair_id, SPOT, 0))
        //                     .write(sources_len - 1);
        //             }
        //             let mut publishers_list = self
        //                 .oracle_list_of_publishers_for_sources_storage
        //                 .entry((source, SPOT, pair_id))
        //                 .read();
        //             publishers_list.clean();
        //             return true;
        //         },
        //         DataType::FutureEntry((
        //             pair_id, expiration_timestamp
        //         )) => {
        //             let sources_len = self
        //                 .oracle_sources_len_storage
        //                 .entry((pair_id, FUTURE, expiration_timestamp))
        //                 .read();
        //             let mut cur_idx = 0;
        //             let is_in_storage: bool = loop {
        //                 if (cur_idx == sources_len) {
        //                     break false;
        //                 }
        //                 let cur_source = self
        //                     .oracle_sources_storage
        //                     .entry((pair_id, SPOT, cur_idx, 0))
        //                     .read();
        //                 if (source == cur_source) {
        //                     break true;
        //                 }
        //                 cur_idx += 1;
        //             };
        //             if (!is_in_storage) {
        //                 panic(array![OracleErrors::SOURCE_NOT_FOUND]);
        //             }
        //             if (cur_idx == sources_len - 1) {
        //                 self
        //                     .oracle_sources_len_storage
        //                     .entry((pair_id, FUTURE, expiration_timestamp))
        //                     .write(sources_len - 1);
        //                 self
        //                     .oracle_sources_storage
        //                     .entry((pair_id, FUTURE, sources_len - 1, expiration_timestamp))
        //                     .write(0);
        //             } else {
        //                 let last_source = self
        //                     .oracle_sources_storage
        //                     .entry((pair_id, FUTURE, sources_len - 1, expiration_timestamp))
        //                     .read();
        //                 self
        //                     .oracle_sources_storage
        //                     .entry((pair_id, FUTURE, cur_idx, expiration_timestamp))
        //                     .write(last_source);
        //                 self
        //                     .oracle_sources_storage
        //                     .entry((pair_id, FUTURE, sources_len - 1, expiration_timestamp))
        //                     .write(0);
        //                 self
        //                     .oracle_sources_len_storage
        //                     .entry((pair_id, FUTURE, expiration_timestamp))
        //                     .write(sources_len - 1);
        //             }
        //             let mut publishers_list = self
        //                 .oracle_list_of_publishers_for_sources_storage
        //                 .entry((source, FUTURE, pair_id))
        //                 .read();
        //             publishers_list.clean();
        //             return true;
        //         },
        //         DataType::GenericEntry(key) => {
        //             let sources_len = self
        //                 .oracle_sources_len_storage
        //                 .entry((key, GENERIC, 0))
        //                 .read();
        //             let mut cur_idx = 0;
        //             let is_in_storage: bool = loop {
        //                 if (cur_idx == sources_len) {
        //                     break false;
        //                 }
        //                 let cur_source = self
        //                     .oracle_sources_storage
        //                     .entry((key, GENERIC, cur_idx, 0))
        //                     .read();
        //                 if (source == cur_source) {
        //                     break true;
        //                 }
        //                 cur_idx += 1;
        //             };
        //             if (!is_in_storage) {
        //                 panic(array![OracleErrors::SOURCE_NOT_FOUND]);
        //             }
        //             if (cur_idx == sources_len - 1) {
        //                 self
        //                     .oracle_sources_len_storage
        //                     .entry((key, GENERIC, 0))
        //                     .write(sources_len - 1);
        //                 self
        //                     .oracle_sources_storage
        //                     .entry((key, GENERIC, sources_len - 1, 0))
        //                     .write(0);
        //             } else {
        //                 let last_source = self
        //                     .oracle_sources_storage
        //                     .entry((key, GENERIC, sources_len - 1, 0))
        //                     .read();
        //                 self
        //                     .oracle_sources_storage
        //                     .entry((key, GENERIC, cur_idx, 0))
        //                     .write(last_source);
        //                 self
        //                     .oracle_sources_storage
        //                     .entry((key, GENERIC, sources_len - 1, 0))
        //                     .write(0);
        //                 self
        //                     .oracle_sources_len_storage
        //                     .entry((key, GENERIC, 0))
        //                     .write(sources_len - 1);
        //             }
        //             let mut publishers_list = self
        //                 .oracle_list_of_publishers_for_sources_storage
        //                 .entry((source, GENERIC, key))
        //                 .read();
        //             publishers_list.clean();
        //             return true;
        //         }
        //     }
        // }

        // @notice set a new checkpoint for a given data type and and aggregation mode
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param aggregation_mode: the aggregation method to be used
        fn set_checkpoint(
            ref self: ContractState, data_type: DataType, aggregation_mode: AggregationMode
        ) {
            let mut sources = ArrayTrait::<felt252>::new().span();
            let priceResponse = self.get_data_for_sources(data_type, aggregation_mode, sources);
            assert(
                !priceResponse.last_updated_timestamp.is_zero(),
                OracleErrors::NO_CHECKPOINT_AVAILABLE
            );

            let sources_threshold = self.oracle_sources_threshold_storage.read();
            let cur_checkpoint = self.get_latest_checkpoint(data_type, aggregation_mode);
            let timestamp: u64 = get_block_timestamp();
            let next_checkpoint_timestamp = cur_checkpoint.timestamp + 1;
            if (sources_threshold < priceResponse.num_sources_aggregated
                && (next_checkpoint_timestamp < timestamp)) {
                let new_checkpoint = Checkpoint {
                    timestamp: timestamp,
                    value: priceResponse.price,
                    aggregation_mode: aggregation_mode,
                    num_sources_aggregated: priceResponse.num_sources_aggregated
                };

                match data_type {
                    DataType::SpotEntry(pair_id) => {
                        let cur_idx = self
                            .oracle_checkpoint_index
                            .entry((pair_id, SPOT, 0, aggregation_mode.try_into().unwrap()))
                            .read();

                        self
                            .set_checkpoint_storage(
                                pair_id,
                                SPOT,
                                cur_idx,
                                0,
                                aggregation_mode.try_into().unwrap(),
                                new_checkpoint
                            );
                        self
                            .oracle_checkpoint_index
                            .entry((pair_id, SPOT, 0, aggregation_mode.try_into().unwrap()))
                            .write(cur_idx + 1);
                        self
                            .emit(
                                Event::CheckpointSpotEntry(
                                    CheckpointSpotEntry { pair_id, checkpoint: new_checkpoint }
                                )
                            );
                    },
                    DataType::FutureEntry((
                        pair_id, expiration_timestamp
                    )) => {
                        let cur_idx = self
                            .oracle_checkpoint_index
                            .entry(
                                (
                                    pair_id,
                                    FUTURE,
                                    expiration_timestamp,
                                    aggregation_mode.try_into().unwrap()
                                )
                            )
                            .read();

                        self
                            .set_checkpoint_storage(
                                pair_id,
                                FUTURE,
                                cur_idx,
                                expiration_timestamp,
                                aggregation_mode.try_into().unwrap(),
                                new_checkpoint
                            );
                        self
                            .oracle_checkpoint_index
                            .entry(
                                (
                                    pair_id,
                                    FUTURE,
                                    expiration_timestamp,
                                    aggregation_mode.try_into().unwrap()
                                )
                            )
                            .write(cur_idx + 1);
                        self
                            .emit(
                                Event::CheckpointFutureEntry(
                                    CheckpointFutureEntry {
                                        pair_id, expiration_timestamp, checkpoint: new_checkpoint
                                    }
                                )
                            );
                    },
                    DataType::GenericEntry(_) => { // TODO: Issue #28
                    },
                }
            }
            return ();
        }

        // @notice set checkpoints for a span of data_type, given an aggregation mode
        // @param data_type: a span DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param aggregation_mode: the aggregation method to be used
        fn set_checkpoints(
            ref self: ContractState, data_types: Span<DataType>, aggregation_mode: AggregationMode
        ) {
            let mut cur_idx: u32 = 0;
            loop {
                if (cur_idx == data_types.len()) {
                    break ();
                }
                let data_type: DataType = *data_types.get(cur_idx).unwrap().unbox();
                self.set_checkpoint(data_type, aggregation_mode);
                cur_idx += 1;
            }
        }


        // @notice set the source threshold
        // @param threshold: the new source threshold to be set
        fn set_sources_threshold(ref self: ContractState, threshold: u32) {
            // [Check]
            self.ownable.assert_only_owner();

            // [Effect]
            self.oracle_sources_threshold_storage.write(threshold);
        }
    }

    // ================== COMPONENTS IMPLEMENTATIONS ==================

    // Upgradeable impl
    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            // [Check] Only owner
            self.ownable.assert_only_owner();
            // [Effect] Upgrade contract
            self.upgradeable.upgrade(new_class_hash);
        }
    }


    // ================== PRIVATE IMPLEMENTATIONS ==================

    #[generate_trait]
    impl OracleInternal of IOracleInternalTrait {
        fn _set_keys_currencies(ref self: ContractState, key_currencies: Span<Currency>) {
            for i in 0
                ..key_currencies
                    .len() {
                        let key_currency = *key_currencies.at(i);
                        assert(key_currency.id != 0, OracleErrors::CURRENCY_CANNOT_BE_NULL);
                        self.oracle_currencies_storage.entry(key_currency.id).write(key_currency);
                    };
            return ();
        }
        // @notice set the keys pairs, called by the constructor of the contract
        // @dev internal function
        fn _set_keys_pairs(ref self: ContractState, key_pairs: Span<Pair>) {
            for i in 0
                ..key_pairs
                    .len() {
                        let key_pair = *key_pairs.at(i);
                        assert(key_pair.id != 0, OracleErrors::PAIR_ID_CANNOT_BE_NULL);
                        let base_currency = self
                            .oracle_currencies_storage
                            .entry(key_pair.base_currency_id)
                            .read();
                        assert(base_currency.id != 0, OracleErrors::NO_BASE_CURRENCY_REGISTERED);
                        let quote_currency = self
                            .oracle_currencies_storage
                            .entry(key_pair.quote_currency_id)
                            .read();
                        assert(quote_currency.id != 0, OracleErrors::NO_QUOTE_CURRENCY_REGISTERED);
                        self.oracle_pairs_storage.entry(key_pair.id).write(key_pair);
                        self
                            .oracle_pair_id_storage
                            .entry((key_pair.quote_currency_id, key_pair.base_currency_id))
                            .write(key_pair.id);
                    };
            return ();
        }

        // @notice retrieve a checkpoint based on its index
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param checkpoint_index : the index of the checkpoint to consider
        // @param aggregation_mode: the aggregation method used when saving the checkpoint
        // @returns the associated checkpoint
        fn get_checkpoint_by_index(
            self: @ContractState,
            data_type: DataType,
            checkpoint_index: u64,
            aggregation_mode: AggregationMode
        ) -> Checkpoint {
            let checkpoint = match data_type {
                DataType::SpotEntry(pair_id) => {
                    self
                        .get_checkpoint_storage(
                            pair_id, SPOT, checkpoint_index, 0, aggregation_mode.try_into().unwrap()
                        )
                },
                DataType::FutureEntry((
                    pair_id, expiration_timestamp
                )) => {
                    self
                        .get_checkpoint_storage(
                            pair_id,
                            FUTURE,
                            checkpoint_index,
                            expiration_timestamp,
                            aggregation_mode.try_into().unwrap()
                        )
                },
                DataType::GenericEntry(key) => {
                    self
                        .get_checkpoint_storage(
                            key, GENERIC, checkpoint_index, 0, aggregation_mode.try_into().unwrap()
                        )
                }
            };
            assert(!checkpoint.timestamp.is_zero(), OracleErrors::CHECKPOINT_DOES_NOT_EXIST);
            return checkpoint;
        }

        // @notice get the latest checkpoint index
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param aggregation_mode: the aggregation method to be used
        // @returns the index
        // @returns a boolean verifying if a checkpoint is actually set (case 0)
        fn _get_latest_checkpoint_index(
            self: @ContractState, data_type: DataType, aggregation_mode: AggregationMode
        ) -> (u64, bool) {
            let checkpoint_index = match data_type {
                DataType::SpotEntry(pair_id) => {
                    self
                        .oracle_checkpoint_index
                        .entry((pair_id, SPOT, 0, aggregation_mode.try_into().unwrap()))
                        .read()
                },
                DataType::FutureEntry((
                    pair_id, expiration_timestamp
                )) => {
                    self
                        .oracle_checkpoint_index
                        .entry(
                            (
                                pair_id,
                                FUTURE,
                                expiration_timestamp,
                                aggregation_mode.try_into().unwrap()
                            )
                        )
                        .read()
                },
                DataType::GenericEntry(key) => {
                    self
                        .oracle_checkpoint_index
                        .entry((key, GENERIC, 0, aggregation_mode.try_into().unwrap()))
                        .read()
                }
            };

            if (checkpoint_index == 0) {
                return (0, false);
            } else {
                return (checkpoint_index - 1, true);
            }
        }

        // @notice get the list of publisher for a given source
        // @param source: the source to consider
        // @param type_of_data: the type of data to consider (e.g SPOT, FUTURE, GENERIC)
        // @returns a span of publishers
        fn get_publishers_for_source(
            self: @ContractState, source: felt252, type_of_data: felt252, pair_id: felt252
        ) -> Span<felt252> {
            let mut publishers = array![];
            for i in 0
                ..self
                    .oracle_list_of_publishers_for_sources_storage
                    .entry((source, type_of_data, pair_id))
                    .len() {
                        publishers
                            .append(
                                self
                                    .oracle_list_of_publishers_for_sources_storage
                                    .entry((source, type_of_data, pair_id))
                                    .at(i)
                                    .read()
                            );
                    };
            publishers.span()
        }
        // @notice check if the publisher is registered, and allowed to publish the entry, calling
        // the publisher registry contract @param entry: the entry to be published
        fn validate_sender_for_source<T, impl THasBaseEntry: HasBaseEntry<T>, impl TDrop: Drop<T>>(
            self: @ContractState, _entry: T
        ) {
            let publisher_registry_address = self.get_publisher_registry_address();
            let publisher_registry_dispatcher = IPublisherRegistryABIDispatcher {
                contract_address: publisher_registry_address
            };
            let publisher_address = publisher_registry_dispatcher
                .get_publisher_address(_entry.get_base_entry().publisher);
            let _can_publish_source = publisher_registry_dispatcher
                .can_publish_source(
                    _entry.get_base_entry().publisher, _entry.get_base_entry().source
                );
            let caller_address = get_caller_address();

            assert(!publisher_address.is_zero(), PublisherErrors::PUBLISHER_NOT_FOUND);
            assert(!caller_address.is_zero(), OracleErrors::CALLER_CANNOT_BE_ZERO);
            assert(
                caller_address == publisher_address, PublisherErrors::TRANSACTION_NOT_FROM_PUBLISHER
            );
            assert(_can_publish_source == true, OracleErrors::NOT_ALLOWED_FOR_SOURCE);
            return ();
        }

        // @notice retrieve the latest entry timestamp for a given data type and and sources
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param a span of sources
        // @returns the latest timestamp
        fn get_latest_entry_timestamp(
            self: @ContractState, data_type: DataType, sources: Span<felt252>,
        ) -> u64 {
            let mut cur_idx = 0;
            let mut latest_timestamp = 0;
            let (storage_bool, type_of_data, pair_id) = match data_type {
                DataType::SpotEntry(pair_id) => {
                    (
                        self.oracle_data_len_all_sources.entry((pair_id, SPOT, 0)).read(),
                        SPOT,
                        pair_id
                    )
                },
                DataType::FutureEntry((
                    pair_id, expiration_timestamp
                )) => {
                    (
                        self
                            .oracle_data_len_all_sources
                            .entry((pair_id, FUTURE, expiration_timestamp))
                            .read(),
                        FUTURE,
                        pair_id
                    )
                },
                DataType::GenericEntry(key) => {
                    (self.oracle_data_len_all_sources.entry((key, GENERIC, 0)).read(), GENERIC, key)
                }
            };

            if (!storage_bool) {
                return 0;
            } else {
                loop {
                    if (cur_idx == sources.len()) {
                        break ();
                    }
                    let source: felt252 = *sources.get(cur_idx).unwrap().unbox();
                    let publishers = self
                        .get_publishers_for_source(
                            source, type_of_data, pair_id
                        ); // In case a publisher cannot add data for another data type, will require a check before
                    let mut publisher_cur_idx = 0;
                    loop {
                        if (publisher_cur_idx == publishers.len()) {
                            break ();
                        }
                        let publisher: felt252 = *publishers
                            .get(publisher_cur_idx)
                            .unwrap()
                            .unbox();
                        let entry: PossibleEntries = self
                            .get_data_entry(data_type, source, publisher);

                        match entry {
                            PossibleEntries::Spot(spot_entry) => {
                                if spot_entry.base.timestamp > latest_timestamp {
                                    latest_timestamp = spot_entry.base.timestamp;
                                }
                            },
                            PossibleEntries::Future(future_entry) => {
                                if future_entry.base.timestamp > latest_timestamp {
                                    latest_timestamp = future_entry.base.timestamp;
                                }
                            },
                            PossibleEntries::Generic(generic_entry) => {
                                if generic_entry.base.timestamp > latest_timestamp {
                                    latest_timestamp = generic_entry.base.timestamp;
                                }
                            }
                        }
                        publisher_cur_idx += 1;
                    };
                    cur_idx += 1;
                };
                return latest_timestamp;
            }
        }

        // @notice build an array of PossibleEntries (spot entries, future entries, ...)
        // @dev recursive function
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param sources: a span of sources to consider
        // @aram entries: a reference to an array of PossibleEntries , to be filled
        // @param latest_timestamp : max wanted timestamp
        fn build_entries_array(
            self: @ContractState,
            data_type: DataType,
            sources: Span<felt252>,
            ref entries: Array<PossibleEntries>,
            latest_timestamp: u64
        ) {
            let (type_of_data, pair_id) = match data_type {
                DataType::SpotEntry(pair_id) => (SPOT, pair_id),
                DataType::FutureEntry((pair_id, _)) => (FUTURE, pair_id),
                DataType::GenericEntry(key) => (GENERIC, key)
            };
            let mut cur_idx = 0;
            loop {
                if (cur_idx >= sources.len()) {
                    break ();
                }
                let source: felt252 = *sources.get(cur_idx).unwrap().unbox();
                let publishers = self.get_publishers_for_source(source, type_of_data, pair_id);
                assert(publishers.len() != 0, PublisherErrors::NO_PUBLISHER_FOR_SOURCE);
                let mut publisher_cur_idx = 0;

                loop {
                    if (publisher_cur_idx >= publishers.len()) {
                        break ();
                    }
                    let publisher: felt252 = *publishers.get(publisher_cur_idx).unwrap().unbox();
                    let g_entry: PossibleEntries = self
                        .get_data_entry(data_type, source, publisher);

                    match g_entry {
                        PossibleEntries::Spot(spot_entry) => {
                            let is_entry_initialized: bool = spot_entry.get_base_timestamp() != 0;
                            let condition: bool = is_entry_initialized
                                && (spot_entry
                                    .get_base_timestamp() > (latest_timestamp
                                        - BACKWARD_TIMESTAMP_BUFFER));
                            if condition {
                                entries.append(PossibleEntries::Spot(spot_entry));
                            }
                        },
                        PossibleEntries::Future(future_entry) => {
                            let is_entry_initialized: bool = future_entry.get_base_timestamp() != 0;
                            let condition: bool = is_entry_initialized
                                && (future_entry
                                    .get_base_timestamp() > (latest_timestamp
                                        - BACKWARD_TIMESTAMP_BUFFER));
                            if condition {
                                entries.append(PossibleEntries::Future(future_entry));
                            }
                        },
                        PossibleEntries::Generic(generic_entry) => {
                            let is_entry_initialized: bool = generic_entry
                                .get_base_timestamp() != 0;

                            let condition: bool = is_entry_initialized
                                && (generic_entry
                                    .get_base_timestamp() > (latest_timestamp
                                        - BACKWARD_TIMESTAMP_BUFFER));
                            if condition {
                                entries.append(PossibleEntries::Generic(generic_entry));
                            }
                        }
                    };
                    publisher_cur_idx += 1;
                };
                cur_idx += 1;
            };

            return ();
        }


        // @notice retrieve all the entries for a given data type
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param sources: a span of sources to consider
        // @param max_timestamp: max timestamp wanted
        // @returns an array of PossibleEntries
        // @returns the length of the span
        fn get_all_entries(
            self: @ContractState, data_type: DataType, sources: Span<felt252>, max_timestamp: u64
        ) -> (Array<PossibleEntries>, u32) {
            let mut entries = ArrayTrait::<PossibleEntries>::new();

            self.build_entries_array(data_type, sources, ref entries, max_timestamp);
            (entries, entries.len())
        }

        // @notice retrieve all the entries for a given data type and a given source
        // @param array: a span of entries to consider
        // @param source: the source to consider
        // @param type_of_data: the type of data to consider (e.g SPOT, FUTURE, GENERIC)
        // @param pair_id: the pair id to consider
        // @returns a span of entries
        fn filter_array_by_source<
            T,
            impl THasBaseEntry: HasBaseEntry<T>,
            impl TDrop: Drop<T>,
            impl TDestruct: Destruct<T>,
            impl TCopy: Copy<T>,
            impl THasPrice: HasPrice<T>
        >(
            self: @ContractState,
            array: Span<T>,
            source: felt252,
            type_of_data: felt252,
            pair_id: felt252
        ) -> Span<T> {
            let mut cur_idx = 0;
            let mut publisher_filtered_array = ArrayTrait::<T>::new();
            let publishers = self.get_publishers_for_source(source, type_of_data, pair_id);
            loop {
                if (cur_idx == array.len()) {
                    break ();
                }
                let entry = *array.at(cur_idx);
                if (publishers.contains(@entry.get_base_entry().publisher)
                    && (entry.get_base_entry().source == source))
                    && entry.get_price() != 0 {
                    publisher_filtered_array.append(entry);
                }
                cur_idx = cur_idx + 1;
            };
            return publisher_filtered_array.span();
        }


        // @notice compute the median of the publishers for a given source and data type
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param filtered_array: a span of entries to consider
        // @param aggregation_mode: the aggregation method to be used
        // @returns a PragmaPricesResponse (see entry/structs)
        fn compute_median_for_source<
            T,
            impl THasPrice: HasPrice<T>,
            impl THasBaseEntry: HasBaseEntry<T>,
            impl THasPartialOrd: PartialOrd<T>,
            impl TCopy: Copy<T>,
            impl TDrop: Drop<T>
        >(
            self: @ContractState,
            data_type: DataType,
            filtered_array: Span<T>,
            aggregation_mode: AggregationMode
        ) -> PragmaPricesResponse {
            match data_type {
                DataType::SpotEntry(_) => {
                    let price = Entry::aggregate_entries::<T>(filtered_array, aggregation_mode);
                    let last_updated_timestamp = Entry::aggregate_timestamps_max::<
                        T
                    >(filtered_array);

                    return PragmaPricesResponse {
                        price: price,
                        decimals: 0, // we will realise a unique get_decimals call at the end
                        last_updated_timestamp: last_updated_timestamp,
                        num_sources_aggregated: 0, //will be fulled at the end
                        expiration_timestamp: Option::Some(0),
                        // Should be None
                    };
                },
                DataType::FutureEntry((
                    _, expiration_timestamp
                )) => {
                    let price = Entry::aggregate_entries::<T>(filtered_array, aggregation_mode);
                    let last_updated_timestamp = Entry::aggregate_timestamps_max::<
                        T
                    >(filtered_array);

                    return PragmaPricesResponse {
                        price: price,
                        decimals: 0,
                        last_updated_timestamp: last_updated_timestamp,
                        num_sources_aggregated: 0,
                        expiration_timestamp: Option::Some(expiration_timestamp),
                        // Should be None
                    };
                },
                DataType::GenericEntry(_) => {
                    let price = Entry::aggregate_entries::<T>(filtered_array, aggregation_mode);
                    let last_updated_timestamp = Entry::aggregate_timestamps_max::<
                        T
                    >(filtered_array);

                    return PragmaPricesResponse {
                        price: price,
                        decimals: 0,
                        last_updated_timestamp: last_updated_timestamp,
                        num_sources_aggregated: 0,
                        expiration_timestamp: Option::Some(0),
                        // Should be None
                    };
                }
            }
        }


        // @notice check if the timestamp of the new entry is bigger than the timestamp of the old
        // entry, and update the source storage @dev should fail if the old_timestamp >
        // new_timestamp @param new_entry : an entry (spot entry, future entry, ... )
        // @param last_entry : an entry (with the same nature as new_entry)
        fn validate_data_timestamp<T, impl THasBaseEntry: HasBaseEntry<T>, impl TDrop: Drop<T>>(
            ref self: ContractState, new_entry: PossibleEntries, last_entry: T,
        ) {
            let current_timestamp = get_block_timestamp();
            match new_entry {
                PossibleEntries::Spot(spot_entry) => {
                    assert(
                        spot_entry.get_base_timestamp() >= last_entry.get_base_timestamp(),
                        OracleErrors::EXISTING_ENTRY_IS_MORE_RECENT
                    );
                    assert(
                        spot_entry.get_base_timestamp() <= current_timestamp
                            + FORWARD_TIMESTAMP_BUFFER,
                        OracleErrors::TIMESTAMP_IS_IN_THE_FUTURE
                    );
                    assert(
                        spot_entry.get_base_timestamp() != 0, OracleErrors::TIMESTAMP_CANNOT_BE_ZERO
                    );
                    if (last_entry.get_base_timestamp() == 0) {
                        let sources_len = self
                            .oracle_sources_len_storage
                            .entry((spot_entry.pair_id, SPOT, 0))
                            .read();
                        self
                            .oracle_sources_storage
                            .entry((spot_entry.pair_id, SPOT, sources_len, 0))
                            .write(spot_entry.get_base_entry().source);
                        self
                            .oracle_sources_len_storage
                            .entry((spot_entry.pair_id, SPOT, 0))
                            .write(sources_len + 1);
                    }
                },
                PossibleEntries::Future(future_entry) => {
                    assert(
                        future_entry.get_base_timestamp() >= last_entry.get_base_timestamp(),
                        OracleErrors::EXISTING_ENTRY_IS_MORE_RECENT
                    );
                    assert(
                        future_entry.get_base_timestamp() != 0,
                        OracleErrors::TIMESTAMP_CANNOT_BE_ZERO
                    );
                    assert(
                        future_entry.get_base_timestamp() <= current_timestamp
                            + FORWARD_TIMESTAMP_BUFFER,
                        OracleErrors::TIMESTAMP_IS_IN_THE_FUTURE
                    );
                    if (last_entry.get_base_timestamp() == 0) {
                        let sources_len = self
                            .oracle_sources_len_storage
                            .entry(
                                (future_entry.pair_id, FUTURE, future_entry.expiration_timestamp)
                            )
                            .read();
                        self
                            .oracle_sources_storage
                            .entry(
                                (
                                    future_entry.pair_id,
                                    FUTURE,
                                    sources_len,
                                    future_entry.expiration_timestamp
                                )
                            )
                            .write(future_entry.get_base_entry().source);
                        self
                            .oracle_sources_len_storage
                            .entry(
                                (future_entry.pair_id, FUTURE, future_entry.expiration_timestamp)
                            )
                            .write(sources_len + 1);
                    }
                },
                PossibleEntries::Generic(generic_entry) => {
                    assert(
                        generic_entry.get_base_timestamp() >= last_entry.get_base_timestamp(),
                        OracleErrors::EXISTING_ENTRY_IS_MORE_RECENT
                    );
                    assert(
                        generic_entry.get_base_timestamp() <= current_timestamp
                            + FORWARD_TIMESTAMP_BUFFER,
                        OracleErrors::TIMESTAMP_IS_IN_THE_FUTURE
                    );
                    assert(
                        generic_entry.get_base_timestamp() != 0,
                        OracleErrors::TIMESTAMP_CANNOT_BE_ZERO
                    );
                    if (last_entry.get_base_timestamp() == 0) {
                        let sources_len = self
                            .oracle_sources_len_storage
                            .entry((generic_entry.key, GENERIC, 0))
                            .read();
                        self
                            .oracle_sources_storage
                            .entry((generic_entry.key, GENERIC, sources_len, 0))
                            .write(generic_entry.get_base_entry().source);
                        self
                            .oracle_sources_len_storage
                            .entry((generic_entry.key, GENERIC, 0))
                            .write(sources_len + 1);
                    }
                }
                // PossibleEntries::OptionEntry(option_entry) => {}
            }
            return ();
        }


        // @notice set source threshold
        // @param the threshold to be set
        fn set_sources_threshold(ref self: ContractState, threshold: u32) {
            self.oracle_sources_threshold_storage.write(threshold);
            return ();
        }


        // @notice find the checkpoint whose timestamp is immediately before the given timestamp
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param aggregation_mode: the aggregation method to be used
        // @param the timestamp to be considered
        // @returns the index of the checkpoint before the given timestamp
        fn find_startpoint(
            self: @ContractState,
            data_type: DataType,
            aggregation_mode: AggregationMode,
            timestamp: u64
        ) -> u64 {
            let (latest_checkpoint_index, _) = self
                ._get_latest_checkpoint_index(data_type, aggregation_mode);

            let cp = self
                .get_checkpoint_by_index(data_type, latest_checkpoint_index, aggregation_mode);

            if (cp.timestamp <= timestamp) {
                return latest_checkpoint_index;
            }
            let first_cp = self.get_checkpoint_by_index(data_type, 0, aggregation_mode);
            if (timestamp < first_cp.timestamp) {
                panic(array![OracleErrors::TIMESTAMP_TOO_OLD]);
            }
            if (timestamp == first_cp.timestamp) {
                return 0;
            }

            let startpoint = self
                .binary_search(data_type, 0, latest_checkpoint_index, timestamp, aggregation_mode);
            return startpoint;
        }


        fn get_entry_storage(
            self: @ContractState,
            key: felt252,
            type_of: felt252,
            source: felt252,
            publisher: felt252,
            expiration_timestamp: u64
        ) -> EntryStorage {
            self
                .oracle_data_entry_storage
                .entry((key, type_of, source, publisher, expiration_timestamp))
                .read()
        }

        fn get_generic_entry_storage(
            self: @ContractState, key: felt252, source: felt252, publisher: felt252,
        ) -> GenericEntryStorage {
            self.oracle_data_generic_entry_storage.entry((key, source, publisher)).read()
        }

        fn set_generic_entry_storage(
            ref self: ContractState,
            key: felt252,
            source: felt252,
            publisher: felt252,
            entry: GenericEntryStorage
        ) {
            self.oracle_data_generic_entry_storage.entry((key, source, publisher)).write(entry);
        }

        fn set_entry_storage(
            ref self: ContractState,
            key: felt252,
            type_of: felt252,
            source: felt252,
            publisher: felt252,
            expiration_timestamp: u64,
            entry: EntryStorage
        ) {
            self
                .oracle_data_entry_storage
                .entry((key, type_of, source, publisher, expiration_timestamp))
                .write(entry);
        }

        fn set_checkpoint_storage(
            ref self: ContractState,
            key: felt252,
            type_of: felt252,
            index: u64,
            expiration_timestamp: u64,
            aggregation_mode: u8,
            checkpoint: Checkpoint
        ) {
            self
                .oracle_checkpoints
                .entry((key, type_of, index, expiration_timestamp, aggregation_mode))
                .write(checkpoint);
        }

        fn get_checkpoint_storage(
            self: @ContractState,
            key: felt252,
            type_of: felt252,
            index: u64,
            expiration_timestamp: u64,
            aggregation_mode: u8
        ) -> Checkpoint {
            self
                .oracle_checkpoints
                .entry((key, type_of, index, expiration_timestamp, aggregation_mode))
                .read()
        }


        fn binary_search(
            self: @ContractState,
            data_type: DataType,
            low: u64,
            high: u64,
            target: u64,
            aggregation_mode: AggregationMode
        ) -> u64 {
            let high_cp = self.get_checkpoint_by_index(data_type, high, aggregation_mode);
            if (high_cp.timestamp <= target) {
                return high;
            }

            // Find the middle point
            let midpoint = (low + high) / 2;

            if midpoint == 0 {
                return 0;
            }
            // If middle point is target.
            let past_midpoint_cp = self
                .get_checkpoint_by_index(data_type, midpoint - 1, aggregation_mode);
            let midpoint_cp = self.get_checkpoint_by_index(data_type, midpoint, aggregation_mode);

            if (midpoint_cp.timestamp == target) {
                return midpoint;
            }

            // If x lies between mid-1 and mid
            if (past_midpoint_cp.timestamp <= target && target <= midpoint_cp.timestamp) {
                return midpoint - 1;
            }

            // If x is smaller than mid, floor
            // must be in left half.
            if (target <= midpoint_cp.timestamp) {
                return self.binary_search(data_type, low, midpoint - 1, target, aggregation_mode);
            }

            // If mid-1 is not floor and x is
            // greater than arr[mid],
            return self.binary_search(data_type, midpoint + 1, high, target, aggregation_mode);
        }


        // @notice retrieve all the sources from the storage and set it in an array
        // @dev recursive function
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param sources: reference to a sources array, to be filled
        // @param sources_len, the max number of sources for the given data_type/aggregation_mode
        fn build_sources_array(
            self: @ContractState, data_type: DataType, ref sources: Array<felt252>, sources_len: u64
        ) {
            let mut idx: u64 = 0;
            loop {
                if (idx == sources_len) {
                    break ();
                }
                match data_type {
                    DataType::SpotEntry(pair_id) => {
                        let new_source = self
                            .oracle_sources_storage
                            .entry((pair_id, SPOT, idx, 0))
                            .read();

                        sources.append(new_source);
                    },
                    DataType::FutureEntry((
                        pair_id, expiration_timestamp
                    )) => {
                        let new_source = self
                            .oracle_sources_storage
                            .entry((pair_id, FUTURE, idx, expiration_timestamp))
                            .read();
                        sources.append(new_source);
                    },
                    DataType::GenericEntry(key) => {
                        let new_source = self
                            .oracle_sources_storage
                            .entry((key, GENERIC, idx, 0))
                            .read();
                        sources.append(new_source);
                    }
                }
                idx = idx + 1;
            };
            return ();
        }


        // @notice retrieve all the publishers from the storage and set it in an array
        // @dev recursive function
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param publishers: reference to a publishers array, to be filled
        // @param publishers_len, the max number of publishers for the given
        // data_type/aggregation_mode
        fn build_publishers_array(
            self: @ContractState,
            data_type: DataType,
            ref publishers: Array<felt252>,
            publishers_len: u64
        ) {
            let mut idx: u64 = 0;
            loop {
                if (idx == publishers_len) {
                    break ();
                }
                match data_type {
                    DataType::SpotEntry(pair_id) => {
                        let new_publisher = self
                            .oracle_publishers_storage
                            .entry((pair_id, SPOT, idx, 0))
                            .read();
                        publishers.append(new_publisher);
                    },
                    DataType::FutureEntry((
                        pair_id, expiration_timestamp
                    )) => {
                        let new_publisher = self
                            .oracle_publishers_storage
                            .entry((pair_id, FUTURE, idx, expiration_timestamp))
                            .read();
                        publishers.append(new_publisher);
                    },
                    DataType::GenericEntry(key) => {
                        let new_publisher = self
                            .oracle_publishers_storage
                            .entry((key, GENERIC, idx, 0))
                            .read();
                        publishers.append(new_publisher);
                    }
                }
                idx = idx + 1;
            };
        }
    }

    // ================== FREE FUNCTIONS ==================

    // @notice retrieve a list of sources from a span of entries
    // @param entries: a span of entries to consider
    // @returns a span of sources
    fn get_sources_from_entries(entries: Span<PossibleEntries>) -> Span<felt252> {
        let mut data_sources = ArrayTrait::<felt252>::new();
        let mut cur_idx = 0;
        loop {
            if (cur_idx == entries.len()) {
                break ();
            }
            let entry = *entries.at(cur_idx);
            match entry {
                PossibleEntries::Spot(spot_entry) => {
                    if (!data_sources.span().contains(@spot_entry.get_base_entry().source)) {
                        data_sources.append(spot_entry.get_base_entry().source);
                    }
                },
                PossibleEntries::Future(future_entry) => {
                    if (!data_sources.span().contains(@future_entry.get_base_entry().source)) {
                        data_sources.append(future_entry.get_base_entry().source);
                    }
                },
                PossibleEntries::Generic(generic_entry) => {
                    if (!data_sources.span().contains(@generic_entry.get_base_entry().source)) {
                        data_sources.append(generic_entry.get_base_entry().source);
                    }
                }
            }
            cur_idx += 1;
        };
        return data_sources.span();
    }

    // @notice generate an ArrayEntry out of a span of possibleEntries
    // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
    // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
    // @param data : the span of possibleEntries
    // @returns an ArrayEntry (see entry/structs)
    fn filter_data_array(data_type: DataType, data: Span<PossibleEntries>) -> ArrayEntry {
        match data_type {
            DataType::SpotEntry(_) => {
                let mut cur_idx = 0;
                let mut spot_entries = ArrayTrait::<SpotEntry>::new();
                loop {
                    if (cur_idx == data.len()) {
                        break ();
                    }
                    let entry = *data.at(cur_idx);
                    match entry {
                        PossibleEntries::Spot(spot_entry) => { spot_entries.append(spot_entry); },
                        PossibleEntries::Future(_) => {},
                        PossibleEntries::Generic(_) => {}
                    }
                    cur_idx = cur_idx + 1;
                };
                ArrayEntry::SpotEntry(spot_entries)
            },
            DataType::FutureEntry((
                _, _
            )) => {
                let mut cur_idx = 0;
                let mut future_entries = ArrayTrait::<FutureEntry>::new();
                loop {
                    if (cur_idx == data.len()) {
                        break ();
                    }
                    let entry = *data.at(cur_idx);
                    match entry {
                        PossibleEntries::Spot(_) => {},
                        PossibleEntries::Future(future_entry) => {
                            future_entries.append(future_entry);
                        },
                        PossibleEntries::Generic(_) => {}
                    }
                    cur_idx = cur_idx + 1;
                };
                ArrayEntry::FutureEntry(future_entries)
            },
            DataType::GenericEntry(_) => {
                let mut cur_idx = 0;
                let mut generic_entries = ArrayTrait::<GenericEntry>::new();
                loop {
                    if (cur_idx == data.len()) {
                        break ();
                    }
                    let entry = *data.at(cur_idx);
                    match entry {
                        PossibleEntries::Spot(_) => {},
                        PossibleEntries::Future(_) => {},
                        PossibleEntries::Generic(generic_entry) => {
                            generic_entries.append(generic_entry);
                        }
                    }
                    cur_idx = cur_idx + 1;
                };
                ArrayEntry::GenericEntry(generic_entries)
            }
        }
    }
}
