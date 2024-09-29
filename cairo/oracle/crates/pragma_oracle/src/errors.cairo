pub mod OracleErrors {
    pub const OWNER_IS_ZERO: felt252 = 'Owner is zero';
    pub const PUBLISHER_REGISTRY_IS_ZERO: felt252 = 'Publisher registry is 0';
    pub const CURRENCY_CANNOT_BE_NULL: felt252 = 'Currency id cannot be null';
    pub const PAIR_ID_CANNOT_BE_NULL: felt252 = 'Pair id cannot be null';
    pub const NO_BASE_CURRENCY_REGISTERED: felt252 = 'No base currency registered';
    pub const NO_QUOTE_CURRENCY_REGISTERED: felt252 = 'No quote currency registered';
    pub const CURRENCY_ID_CANNOT_BE_ZERO: felt252 = 'Currency id cannot be 0';
    pub const CURRENCY_ALREADY_EXISTS_FOR_KEY: felt252 = 'Currency already exists for key';
    pub const CURRENCY_ID_NOT_CORRESPONDING: felt252 = 'Currency id not corresponding';
    pub const NO_CURRENCY_RECORDED: felt252 = 'No currency recorded';
    pub const PAIR_ID_NOT_CORRESPONDING: felt252 = 'Pair id not corresponding';
    pub const NO_PAIR_RECORDED: felt252 = 'No pair recorded';
    pub const PAIR_WITH_THIS_KEY_REGISTERED: felt252 = 'Pair with this key registered';
    pub const WRONG_DATA_TYPE: felt252 = 'Wrong data type';
    pub const EXPIRATION_TIMESTAMP_IS_REQUIRED: felt252 = 'Expiration timestamp required';
    pub const NOT_ALLOWED_FOR_SOURCE: felt252 = 'Not allowed for source';
    pub const CALLER_CANNOT_BE_ZERO: felt252 = 'Caller cannot be 0';
    // SOURCE
    pub const SOURCE_NOT_FOUND: felt252 = 'Source not found';

    // ENTRY
    pub const EXISTING_ENTRY_IS_MORE_RECENT: felt252 = 'Existing entry is more recent';
    pub const NO_DATA_ENTRY_FOUND: felt252 = 'No data entry found';

    // TIMESTAMP
    pub const TIMESTAMP_TOO_OLD: felt252 = 'Timestamp too old';
    pub const TIMESTAMP_IS_IN_THE_FUTURE: felt252 = 'Timestamp is in the future';
    pub const TIMESTAMP_CANNOT_BE_ZERO: felt252 = 'Timestamp cannot be 0';

    // CHECKPOINTS

    pub const NO_CHECKPOINT_AVAILABLE: felt252 = 'No checkpoint available';
}
