use starknet::core::types::Felt;

#[allow(unused)]
#[async_trait::async_trait]
pub trait PragmaWrapperCalls {
    // TODO: Retrieve all data feeds
    async fn get_data_feeds(&self, pragma_wrapper_address: &Felt) -> anyhow::Result<Vec<String>>;
}
