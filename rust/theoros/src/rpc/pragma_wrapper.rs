use starknet::core::types::Felt;

#[allow(unused)]
#[async_trait::async_trait]
pub trait PragmaWrapperCalls {
    /// Retrieves all the available data feeds from the Pragma oracle Wrapper.
    async fn get_data_feeds(&self, pragma_wrapper_address: &Felt) -> anyhow::Result<Vec<String>>;
}
