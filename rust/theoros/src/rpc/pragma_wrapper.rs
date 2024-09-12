use starknet::core::types::Felt;

use super::StarknetRpc;

#[allow(unused)]
#[async_trait::async_trait]
pub trait PragmaWrapperCalls {
    /// Retrieves all the available data feeds from the Pragma oracle Wrapper.
    async fn get_data_feeds(&self, pragma_wrapper_address: &Felt) -> anyhow::Result<Vec<String>>;
}

#[async_trait::async_trait]
impl PragmaWrapperCalls for StarknetRpc {
    async fn get_data_feeds(&self, _pragma_wrapper_address: &Felt) -> anyhow::Result<Vec<String>> {
        Ok(vec![])
    }
}
