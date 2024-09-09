pub mod hyperlane;
pub mod pragma_wrapper;

pub use hyperlane::*;
pub use pragma_wrapper::*;

use pragma_utils::conversions::starknet::felt_vec_to_vec_string;
use starknet::{
    core::types::{BlockId, BlockTag, Felt, FunctionCall},
    macros::selector,
    providers::{jsonrpc::HttpTransport, JsonRpcClient, Provider},
};
use url::Url;

pub struct StarknetRpc(JsonRpcClient<HttpTransport>);

impl StarknetRpc {
    pub fn new(rpc_url: Url) -> Self {
        Self(JsonRpcClient::new(HttpTransport::new(rpc_url)))
    }
}

#[async_trait::async_trait]
impl HyperlaneCalls for StarknetRpc {
    async fn get_announced_storage_locations(
        &self,
        hyperlane_core_address: &Felt,
        validators: &[Felt],
    ) -> anyhow::Result<Vec<String>> {
        let mut calldata = vec![Felt::from(validators.len())];
        calldata.extend(validators);

        let call = FunctionCall {
            contract_address: *hyperlane_core_address,
            entry_point_selector: selector!("get_announced_storage_locations"),
            calldata,
        };

        let response = self.0.call(call, BlockId::Tag(BlockTag::Pending)).await?;
        let storage_locations = felt_vec_to_vec_string(&response)?;
        Ok(storage_locations)
    }

    async fn get_announced_validators(&self, hyperlane_core_address: &Felt) -> anyhow::Result<Vec<Felt>> {
        let call = FunctionCall {
            contract_address: *hyperlane_core_address,
            entry_point_selector: selector!("get_announced_validators"),
            calldata: vec![],
        };
        let response = self.0.call(call, BlockId::Tag(BlockTag::Pending)).await?;
        Ok(response)
    }
}

#[async_trait::async_trait]
impl PragmaWrapperCalls for StarknetRpc {
    async fn get_data_feeds(&self, _pragma_wrapper_address: &Felt) -> anyhow::Result<Vec<String>> {
        Ok(vec![])
    }
}
