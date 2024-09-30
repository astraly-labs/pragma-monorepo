pub mod SummaryStatsErrors {
    // DATA
    pub const INVALID_DATA_TYPE: felt252 = 'Invalid data type';
    pub const NO_DATA_AVAILABLE: felt252 = 'No data available';
    pub const NOT_ENOUGH_DATA: felt252 = 'Not enough data';
    // TIMESTAMP
    pub const START_MUST_BE_LOWER_THAN_STOP: felt252 = 'start must be < stop';

    // VOLAITLITY
    pub const NUM_SAMPLE_MUST_BE_ABOVE_ZERO: felt252 = 'num_samples must be > 0';
    pub const NUM_SAMPLE_IS_TOO_LARGE: felt252 = 'num_samples is too large';
    pub const START_TICK_MUST_BE_LOWER_THAN_END_TICK: felt252 = 'start_tick must be < end_tick';


    // OPTION DATA
    pub const INVALID_PROOF: felt252 = 'Invalid proof';
}
