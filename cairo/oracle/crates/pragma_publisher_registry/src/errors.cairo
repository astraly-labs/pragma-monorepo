pub mod PublisherErrors {
    pub const OWNER_IS_ZERO: felt252 = 'Owner cannot be 0';
    pub const ADDRESS_ALREADY_REGISTERED: felt252 = 'Address already registered';
    pub const NAME_ALREADY_REGISTERED: felt252 = 'Pbsher name already registered';
    pub const CANNOT_SET_ADDRESS_TO_ZERO: felt252 = 'Cannot set address to zero';
    pub const NAME_NOT_REGISTERED: felt252 = 'Pbsher name not registered';
    pub const CALLER_IS_NOT_PUBLISHER: felt252 = 'Caller is not the publisher';
    pub const PUBLISHER_ADDDRESS_CANNOT_BE_ZERO: felt252 = 'Publishr address cannot be zero';
    pub const PUBLISHER_NOT_FOUND: felt252 = 'Publisher not found';
    pub const SOURCE_ALREADY_REGISTERED: felt252 = 'Source already registered';
    pub const NO_SOURCES_FOR_PUBLISHER: felt252 = 'No sources for publisher';
    pub const SOURCE_NOT_FOUND_FOR_PUBLISHER: felt252 = 'Source not found for publisher';
    pub const TRANSACTION_NOT_FROM_PUBLISHER: felt252 = 'Transaction not from publisher';
    pub const NO_PUBLISHER_FOR_SOURCE: felt252 = 'No publisher for source';
}
