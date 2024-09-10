use starknet::{
    core::types::{BlockId, BlockTag, Felt, FunctionCall},
    macros::selector,
    providers::Provider,
};

use pragma_utils::conversions::starknet::felt_vec_to_vec_string;

use super::StarknetRpc;

#[async_trait::async_trait]
pub trait HyperlaneCalls {
    /// Retrieves the announced storage locations as a [Vec<String>] from the
    /// hyperlane core contract.
    /// The strings are all storage locations path.
    async fn get_announced_storage_locations(
        &self,
        hyperlane_core_address: &Felt,
        validators: &[Felt],
    ) -> anyhow::Result<Vec<String>>;

    /// Retrieves all the announced validators as a [Vec<Felt>] from the hyperlane
    /// core contract.
    /// The felts are validators addresses.
    async fn get_announced_validators(&self, hyperlane_core_address: &Felt) -> anyhow::Result<Vec<Felt>>;
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
