use anyhow::Result;
use starknet::{
    core::types::{BlockId, BlockTag, EthAddress, Felt, FunctionCall},
    macros::selector,
    providers::{jsonrpc::HttpTransport, JsonRpcClient, Provider},
};
use url::Url;

use super::StorageLocation;

pub struct StarknetRpc(JsonRpcClient<HttpTransport>);

impl StarknetRpc {
    pub fn new(rpc_url: Url) -> Self {
        Self(JsonRpcClient::new(HttpTransport::new(rpc_url)))
    }

    pub async fn get_announced_storage_locations(
        &self,
        hyperlane_core_address: &str,
        validators: &[EthAddress],
    ) -> Result<Vec<StorageLocation>> {
        let hyperlane_core_address = Felt::from_hex(hyperlane_core_address)?;

        let validators: Vec<Felt> = validators.iter().cloned().map(Felt::from).collect();

        let mut calldata = vec![Felt::from(validators.len())];
        calldata.extend(validators);

        let call = FunctionCall {
            contract_address: hyperlane_core_address,
            entry_point_selector: selector!("get_announced_storage_locations"),
            calldata,
        };

        let _response = self.0.call(call, BlockId::Tag(BlockTag::Pending)).await?;
        // TODO: Decode response into Vec<StorageLocation>
        Ok(vec![])
    }
}
