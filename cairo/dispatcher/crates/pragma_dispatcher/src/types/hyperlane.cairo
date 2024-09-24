use alexandria_bytes::Bytes;
use starknet::ContractAddress;

pub type HyperlaneMessageId = u256;

/// Re-definition of the Mailbox interface with only the methods we will call.
/// Source: https://github.com/astraly-labs/hyperlane_starknet
#[starknet::interface]
pub trait IMailbox<TContractState> {
    fn dispatch(
        ref self: TContractState,
        _destination_domain: u32,
        _recipient_address: u256,
        _message_body: Bytes,
        _fee_amount: u256,
        _custom_hook_metadata: Option<Bytes>,
        _custom_hook: Option<ContractAddress>,
    ) -> u256;
}
