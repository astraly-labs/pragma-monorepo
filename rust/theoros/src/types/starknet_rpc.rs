use anyhow::Result;
use pragma_utils::conversions::starknet::felt_vec_to_vec_string;
use starknet::{
    core::types::{BlockId, BlockTag, EthAddress, Felt, FunctionCall},
    macros::selector,
    providers::{jsonrpc::HttpTransport, JsonRpcClient, Provider},
};
use url::Url;

pub struct StarknetRpc(JsonRpcClient<HttpTransport>);

impl StarknetRpc {
    pub fn new(rpc_url: Url) -> Self {
        Self(JsonRpcClient::new(HttpTransport::new(rpc_url)))
    }

    /// Retrieves a [Vec] of [String] (storage locations) from the hyperlane core contract.
    pub async fn get_announced_storage_locations(
        &self,
        hyperlane_core_address: &str,
        validators: &[EthAddress],
    ) -> Result<Vec<String>> {
        let hyperlane_core_address = Felt::from_hex(hyperlane_core_address)?;

        let validators: Vec<Felt> = validators.iter().cloned().map(Felt::from).collect();

        let mut calldata = vec![Felt::from(validators.len())];
        calldata.extend(validators);

        let call = FunctionCall {
            contract_address: hyperlane_core_address,
            entry_point_selector: selector!("get_announced_storage_locations"),
            calldata,
        };

        let response = self.0.call(call, BlockId::Tag(BlockTag::Pending)).await?;
        let storage_locations = felt_vec_to_vec_string(&response)?;
        Ok(storage_locations)
    }

    // TODO: get_announced_validators
}
