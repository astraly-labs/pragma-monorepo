use core::starknet::{ContractAddress, ClassHash};

pub trait IPragmaDispatcher<TContractState> {
    fn owner(self: @TContractState) -> ContractAddress;
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress);
    fn renounce_ownership(ref self: TContractState);
    /// Upgrade the Pragma Dispatcjer smart contract
    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);
}
