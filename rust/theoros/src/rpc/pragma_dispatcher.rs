use pragma_utils::conversions::starknet::felt_vec_to_vec_string;
use starknet::{
    core::types::{BlockId, BlockTag, Felt, FunctionCall},
    macros::selector,
    providers::Provider,
};

use super::StarknetRpc;

#[allow(unused)]
#[async_trait::async_trait]
pub trait PragmaDispatcherCalls {
    /// Retrieves the feed registry address from the Pragma oracle Wrapper.
    async fn get_pragma_feed_registry_address(&self, pragma_dispatcher_address: &Felt) -> anyhow::Result<Felt>;
    /// Retrieves all the available data feeds from the Pragma oracle Wrapper.
    async fn get_data_feeds(&self, feed_registry_address: &Felt) -> anyhow::Result<Vec<String>>;
}

#[async_trait::async_trait]
impl PragmaDispatcherCalls for StarknetRpc {
    async fn get_data_feeds(&self, feed_registry_address: &Felt) -> anyhow::Result<Vec<String>> {
        let call = FunctionCall {
            contract_address: *feed_registry_address,
            entry_point_selector: selector!("get_all_feeds"),
            calldata: vec![],
        };

        let mut response = self.0.call(call, BlockId::Tag(BlockTag::Pending)).await?;
        response.insert(0, Felt::from(1)); // to fit the format given in the function
        Ok(felt_vec_to_vec_string(&response)?)
    }

    async fn get_pragma_feed_registry_address(&self, pragma_dispatcher_address: &Felt) -> anyhow::Result<Felt> {
        let call = FunctionCall {
            contract_address: *pragma_dispatcher_address,
            entry_point_selector: selector!("get_pragma_feed_registry_address"),
            calldata: vec![],
        };

        let response = self.0.call(call, BlockId::Tag(BlockTag::Pending)).await?;

        Ok(response[0])
    }
}
