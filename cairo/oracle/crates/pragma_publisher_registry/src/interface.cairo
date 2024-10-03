use starknet::ContractAddress;

#[starknet::interface]
pub trait IPublisherRegistryABI<TContractState> {
    fn add_publisher(
        ref self: TContractState, publisher: felt252, publisher_address: ContractAddress
    );
    fn update_publisher_address(
        ref self: TContractState, publisher: felt252, new_publisher_address: ContractAddress
    );
    fn remove_publisher(ref self: TContractState, publisher: felt252);
    fn add_source_for_publisher(ref self: TContractState, publisher: felt252, source: felt252);
    fn add_sources_for_publisher(
        ref self: TContractState, publisher: felt252, sources: Span<felt252>
    );
    fn remove_source_for_publisher(ref self: TContractState, publisher: felt252, source: felt252);
    fn remove_source_for_all_publishers(ref self: TContractState, source: felt252);

    fn can_publish_source(self: @TContractState, publisher: felt252, source: felt252) -> bool;
    fn get_publisher_address(self: @TContractState, publisher: felt252) -> ContractAddress;
    fn get_all_publishers(self: @TContractState) -> Array<felt252>;
    fn get_publisher_sources(self: @TContractState, publisher: felt252) -> Array<felt252>;
}
