#[starknet::contract]
mod SummaryStats {
    use core::hash::HashStateTrait;
    use core::pedersen::PedersenTrait;
    use cubit::f128::types::fixed::{ONE_u128, FixedInto, FixedTrait,};
    use pragma_entry::structures::{OptionsFeedData, DataType, AggregationMode, PossibleEntries};
    use pragma_operations::metrics::{mean, volatility, twap};
    use pragma_operations::structures::TickElem;
    use pragma_oracle::interface::{IOracleABIDispatcher, IOracleABIDispatcherTrait};
    use pragma_summary_stats::errors::SummaryStatsErrors;
    use pragma_summary_stats::interface::{ISummaryStatsABI, DERIBIT_OPTIONS_FEED_ID};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map
    };
    use starknet::{ContractAddress,};
    #[storage]
    struct Storage {
        oracle_address: ContractAddress,
        options_data: Map<felt252, OptionsFeedData>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, oracle_address: ContractAddress) {
        self.oracle_address.write(oracle_address);
    }

    #[derive(Drop, starknet::Event)]
    struct OptionsDataUpdated {
        previous_data: OptionsFeedData,
        new_data: OptionsFeedData
    }

    #[derive(Drop, starknet::Event)]
    #[event]
    enum Event {
        OptionsDataUpdated: OptionsDataUpdated
    }

    #[abi(embed_v0)]
    impl SummaryStatsImpl of ISummaryStatsABI<ContractState> {
        // @notice: compute the mean price for a given data type, for a given interval
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param start: initial timestamp, combined with final_timestamp, it helps define the
        // period over which the mean is computed @param stop : final timestamp.
        // @param aggregation_mode: specifies the method by which the oracle aggregates each price
        // used in the computation @returns the mean price
        // @returns the precision, the number of decimals (the real mean value is mean /
        // (10**decimals))
        fn calculate_mean(
            self: @ContractState,
            data_type: DataType,
            start: u64,
            stop: u64,
            aggregation_mode: AggregationMode
        ) -> (u128, u32) {
            assert(start < stop, SummaryStatsErrors::START_MUST_BE_LOWER_THAN_STOP);
            let oracle_address = self.oracle_address.read();
            let oracle_dispatcher = IOracleABIDispatcher { contract_address: oracle_address };

            let (latest_checkpoint_index, _) = oracle_dispatcher
                .get_latest_checkpoint_index(data_type, aggregation_mode);
            let (cp, start_index) = oracle_dispatcher
                .get_last_checkpoint_before(data_type, start, aggregation_mode);
            let decimals = oracle_dispatcher.get_decimals(data_type);

            let (_, stop_index) = oracle_dispatcher
                .get_last_checkpoint_before(data_type, stop, aggregation_mode);
            if (start_index == stop_index) {
                return (cp.value, decimals);
            }

            if start_index == latest_checkpoint_index {
                return (cp.value, decimals);
            }

            let scaled_arr = SummaryStatsInternal::_make_scaled_array(
                oracle_address, data_type, stop_index - start_index, stop_index, 1, aggregation_mode
            );

            let mean = mean(scaled_arr.span()) / ONE_u128;

            (mean, decimals)
        }

        // @notice Update the options data upon merkle proof verification
        // @param merkle_proof: the merkle proof used to verify the data
        // @param update_data: the new data to be updated
        // @returns the updated data
        fn update_options_data(
            ref self: ContractState, merkle_proof: Span<felt252>, update_data: OptionsFeedData
        ) -> OptionsFeedData {
            let oracle_address = self.oracle_address.read();
            let oracle_dispatcher = IOracleABIDispatcher { contract_address: oracle_address };

            let latest_entry = oracle_dispatcher
                .get_data_entries(DataType::GenericEntry(DERIBIT_OPTIONS_FEED_ID))
                .get(0);
            let merkle_root = match latest_entry {
                Option::Some(entry) => {
                    match entry.unbox() {
                        PossibleEntries::Spot(_) => {
                            panic(array![SummaryStatsErrors::INVALID_DATA_TYPE]);
                            Default::default()
                        },
                        PossibleEntries::Future(_) => {
                            panic(array![SummaryStatsErrors::INVALID_DATA_TYPE]);
                            Default::default()
                        },
                        PossibleEntries::Generic(entry) => { entry },
                    }
                },
                Option::None => {
                    panic(array![SummaryStatsErrors::NO_DATA_AVAILABLE]);
                    Default::default()
                }
            };

            // Verify the merkle proof
            let leaf = self.get_options_data_hash(update_data);

            let merkle_root_felt: felt252 = (*merkle_root.value).try_into().unwrap();
            assert(
                merkle_root_felt == SummaryStatsInternal::compute_pedersen_root(leaf, merkle_proof),
                SummaryStatsErrors::INVALID_PROOF
            );

            // Update the data
            let old_data = self.options_data.entry(update_data.instrument_name).read();
            self.options_data.entry(update_data.instrument_name).write(update_data);

            self
                .emit(
                    Event::OptionsDataUpdated(
                        OptionsDataUpdated { previous_data: old_data, new_data: update_data }
                    )
                );

            update_data
        }

        // @notice Get the options data
        fn get_options_data(self: @ContractState, instrument_name: felt252) -> OptionsFeedData {
            self.options_data.entry(instrument_name).read()
        }

        // @notice Get the hash of the options data
        fn get_options_data_hash(self: @ContractState, update_data: OptionsFeedData) -> felt252 {
            let mut serialized_struct: Array<felt252> = ArrayTrait::new();
            Serde::serialize(@update_data, ref serialized_struct);
            let data_len = serialized_struct.len();
            let mut state = PedersenTrait::new(0);

            loop {
                match serialized_struct.pop_front() {
                    Option::Some(value) => { state = state.update(value); },
                    Option::None => { break (); },
                };
            };

            // Add length to avoid collisions
            state = state.update(data_len.into());

            // leaf is the result of hashing only the fields of the struct
            state.finalize()
        }


        // @notice computes the realised volatility for a given data type and a given interval
        // @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param start_tick: initial timestamp, combined with final_timestamp, it helps define the
        // period over which the mean is computed @param end_tick : final timestamp.
        // @param num_samples: the number of subdivision of the initial interval used for the
        // computation @param aggregation_mode: specifies the method by which the oracle aggregates
        // each price used in the computation @returns the realized volatility
        // @returns the precision, the number of decimals (the real mean value is mean /
        // (10**decimals))
        fn calculate_volatility(
            self: @ContractState,
            data_type: DataType,
            start_tick: u64,
            end_tick: u64,
            num_samples: u64,
            aggregation_mode: AggregationMode,
        ) -> (u128, u32) {
            let oracle_address = self.oracle_address.read();

            assert(num_samples > 0, SummaryStatsErrors::NUM_SAMPLE_MUST_BE_ABOVE_ZERO);
            assert(num_samples <= 200, SummaryStatsErrors::NUM_SAMPLE_IS_TOO_LARGE);

            let oracle_dispatcher = IOracleABIDispatcher { contract_address: oracle_address };
            let (latest_checkpoint_index, _) = oracle_dispatcher
                .get_latest_checkpoint_index(data_type, aggregation_mode);
            let (_start_cp, start_index) = oracle_dispatcher
                .get_last_checkpoint_before(data_type, start_tick, aggregation_mode);

            let mut end_index = 0;
            if (end_tick == 0) {
                end_index = latest_checkpoint_index;
            } else {
                let (_end_cp, _end_idx) = oracle_dispatcher
                    .get_last_checkpoint_before(data_type, end_tick, aggregation_mode);
                end_index = _end_idx;
            }
            assert(
                start_index < end_index, SummaryStatsErrors::START_TICK_MUST_BE_LOWER_THAN_END_TICK
            );
            assert(start_index != latest_checkpoint_index, SummaryStatsErrors::NOT_ENOUGH_DATA);
            let mut tick_arr = ArrayTrait::<TickElem>::new();
            let skip_frequency = SummaryStatsInternal::calculate_skip_frequency(
                end_index - start_index, num_samples
            );
            let mut idx = 0;
            loop {
                if (end_index <= idx * skip_frequency + start_index) {
                    break ();
                }
                let cp = oracle_dispatcher
                    .get_checkpoint(
                        data_type, idx * skip_frequency + start_index, aggregation_mode
                    );

                let fixed_val = FixedTrait::new(cp.value, false);
                tick_arr.append(TickElem { tick: cp.timestamp, value: fixed_val });
                idx += 1;
            };
            //the number of decimals is hardcoded to 8 by the volatilty computation in metrics.cairo
            (volatility(tick_arr.span()), 8)
        }


        // @notice compute the time weighted average price for a given data type, and a give
        // interval @param data_type: an enum of DataType (e.g : DataType::SpotEntry(ASSET_ID) or
        // DataType::FutureEntry((ASSSET_ID, expiration_timestamp)))
        // @param aggregation_mode: specifies the method by which the oracle aggregates each price
        // used in the computation @param time : represent the DURATION, used for the computation
        // @param start_time: the initial timestamp, the working interval is then [start_time,
        // start_time+time]
        // @returns the time weighted average price
        // @returns the precision, the number of decimals (the real mean value is mean /
        // (10**decimals))
        fn calculate_twap(
            self: @ContractState,
            data_type: DataType,
            aggregation_mode: AggregationMode,
            time: u64,
            start_time: u64
        ) -> (u128, u32) {
            let oracle_address = self.oracle_address.read();
            let oracle_dispatcher = IOracleABIDispatcher { contract_address: oracle_address };
            let (_start_cp, start_index) = oracle_dispatcher
                .get_last_checkpoint_before(data_type, start_time, aggregation_mode);
            let (_stop_cp, stop_index) = oracle_dispatcher
                .get_last_checkpoint_before(data_type, start_time + time, aggregation_mode);
            let decimals = oracle_dispatcher.get_decimals(data_type);
            assert(start_index != stop_index, SummaryStatsErrors::NOT_ENOUGH_DATA);
            let mut tick_arr = ArrayTrait::<TickElem>::new();
            let mut idx = start_index;
            loop {
                if (stop_index < idx) {
                    break ();
                }
                let cp = oracle_dispatcher.get_checkpoint(data_type, idx, aggregation_mode);

                let fixed_val = FixedTrait::new(cp.value, false);
                tick_arr.append(TickElem { tick: cp.timestamp, value: fixed_val });
                idx += 1;
            };
            (twap(tick_arr.span()), decimals)
        }


        fn get_oracle_address(self: @ContractState) -> ContractAddress {
            self.oracle_address.read()
        }
    }


    // ================== PRIVATE IMPLEMENTATIONS ==================

    #[generate_trait]
    impl SummaryStatsInternal of SummaryStatsInternalTrait {
        // @notice create the subdivision, e.g the number by which we need to increment the cursor
        // in order to comply with the given num_samples @param total_samples: the total number of
        // data available within the interval @param num_samples: the number of samples needed
        // @returns the incrementation
        fn calculate_skip_frequency(total_samples: u64, num_samples: u64) -> u64 {
            let skip_frequency = total_samples / num_samples;
            if (skip_frequency == 0) {
                return 1;
            }
            let r = total_samples % num_samples;
            if (r * 2 < num_samples) {
                return skip_frequency;
            } else {
                return skip_frequency + 1;
            }
        }


        // @notice generate an array with incremented entries, complying with the
        // calculate_skip_freqency specification @param oracle_address: the oracle address, used to
        // call functions within the oracle @param data_type: an enum of DataType (e.g :
        // DataType::SpotEntry(ASSET_ID) or DataType::FutureEntry((ASSSET_ID,
        // expiration_timestamp)))
        // @param num_datapoints: the total number of checkpoints available within the given
        // interval @param latest_checkpoint_index : the latest checkpoint index within the given
        // interval @param skip_frequency: the incrementation
        // @param aggregation_mode: specifies the method by which the oracle aggregates each price
        // used in the computation
        fn _make_scaled_array(
            oracle_address: ContractAddress,
            data_type: DataType,
            num_datapoints: u64,
            latest_checkpoint_index: u64,
            skip_frequency: u64,
            aggregation_mode: AggregationMode
        ) -> Array<TickElem> {
            let mut tick_arr = ArrayTrait::<TickElem>::new();
            let mut idx = 0;
            let oracle_dispatcher = IOracleABIDispatcher { contract_address: oracle_address };
            let offset = latest_checkpoint_index - num_datapoints;
            loop {
                if (latest_checkpoint_index < idx * skip_frequency + offset) {
                    break ();
                }
                let cp = oracle_dispatcher
                    .get_checkpoint(data_type, idx * skip_frequency + offset, aggregation_mode);

                tick_arr
                    .append(
                        TickElem {
                            tick: cp.timestamp, value: FixedTrait::new(cp.value * ONE_u128, false)
                        }
                    );
                idx += 1;
            };
            // let _scaled_arr = scale_data(start_tick, end_tick, tick_arr.span(), SCALED_ARR_SIZE);
            return tick_arr;
        }

        fn hash_function(a: felt252, b: felt252) -> felt252 {
            let a_u256: u256 = a.into();
            if a_u256 < b.into() {
                core::pedersen::pedersen(a, b)
            } else {
                core::pedersen::pedersen(b, a)
            }
        }

        // computes the pedersen root of a merkle tree by combining the current node with each
        // sibling up the tree
        fn compute_pedersen_root(current: felt252, mut proof: Span<felt252>) -> felt252 {
            match proof.pop_front() {
                Option::Some(proof_element) => {
                    Self::compute_pedersen_root(Self::hash_function(current, *proof_element), proof)
                },
                Option::None => { current },
            }
        }
    }
}
