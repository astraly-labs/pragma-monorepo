#[starknet::interface]
pub trait IPragmaDispatcher<TContractState> {
    fn dispatch_data_feeds(self: @TContractState, feed_ids: Span<ByteArray>);
}
