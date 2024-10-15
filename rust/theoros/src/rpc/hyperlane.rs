use starknet::{
    core::types::{BlockId, BlockTag, Felt, FunctionCall},
    macros::selector,
    providers::Provider,
};

use pragma_utils::conversions::starknet::process_nested_felt_array;

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
    ) -> anyhow::Result<Vec<Vec<String>>>;

    /// Retrieves all the announced validators as a [Vec<Felt>] from the hyperlane
    /// core contract.
    /// The felts are validators addresses.
    async fn get_announced_validators(&self, hyperlane_core_address: &Felt) -> anyhow::Result<Vec<Felt>>;

    /// Retrieves the latest checkpoint (root, index) tuple from the merkle tree hook contract.
    /// The index is the latest checkpoint index.
    /// The root is the latest checkpoint root.
    async fn get_latest_checkpoint(&self, merkle_tree_hook_address: &Felt) -> anyhow::Result<Vec<Felt>>;
}

#[async_trait::async_trait]
impl HyperlaneCalls for StarknetRpc {
    async fn get_announced_storage_locations(
        &self,
        hyperlane_core_address: &Felt,
        validators: &[Felt],
    ) -> anyhow::Result<Vec<Vec<String>>> {
        let mut calldata = vec![Felt::from(validators.len())];
        calldata.extend(validators);

        let call = FunctionCall {
            contract_address: *hyperlane_core_address,
            entry_point_selector: selector!("get_announced_storage_locations"),
            calldata,
        };

        let mut response = self.0.call(call, BlockId::Tag(BlockTag::Pending)).await?;

        let storage_locations = process_nested_felt_array(&response)?;

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

    async fn get_latest_checkpoint(&self, merkle_tree_hook_address: &Felt) -> anyhow::Result<Vec<Felt>> {
        let call = FunctionCall {
            contract_address: *merkle_tree_hook_address,
            entry_point_selector: selector!("get_latest_checkpoint"),
            calldata: vec![],
        };
        let response = self.0.call(call, BlockId::Tag(BlockTag::Pending)).await?;
        Ok(response)
    }
}
