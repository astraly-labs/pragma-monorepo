pub mod EntryErrors {
    pub const TIMESTAMP_TOO_BIG: felt252 = 'EntryStorePack:tmp too big';
    pub const VOLUME_TOO_BIG: felt252 = 'EntryStorePack:volume too big';
    pub const PRICE_TOO_BIG: felt252 = 'EntryStorePack:price too big';
    pub const DATA_TOO_BIG: felt252 = 'EntryStorePack: data too big';
    pub const WRONG_AGGREGATION_MODE: felt252 = 'Wrong aggregation mode';
    pub const ENTRIES_MUST_NOT_BE_EMPTY: felt252 = 'entries must not be empty';
}
