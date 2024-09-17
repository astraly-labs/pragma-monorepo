use alexandria_bytes::Bytes;

#[starknet::interface]
pub trait IFeedTypeRouter<TContractState> {
    fn get_data(self: @TContractState) -> Bytes;
}
