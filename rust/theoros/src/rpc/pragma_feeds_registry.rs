use pragma_utils::conversions::starknet::felt_vec_to_vec_string;
use starknet::{
    core::types::{BlockId, BlockTag, Felt, FunctionCall},
    macros::selector,
    providers::Provider,
};

use super::StarknetRpc;

const PENDING_BLOCK: BlockId = BlockId::Tag(BlockTag::Pending);

#[async_trait::async_trait]
pub trait PragmaFeedsRegistryCalls {
    /// Retrieves all the available feed ids from the Pragma Feeds Registry.
    async fn get_feed_ids(&self, pragma_feeds_registry_address: &Felt) -> anyhow::Result<Vec<String>>;
}

#[async_trait::async_trait]
impl PragmaFeedsRegistryCalls for StarknetRpc {
    async fn get_feed_ids(&self, pragma_feeds_registry_address: &Felt) -> anyhow::Result<Vec<String>> {
        let call = FunctionCall {
            contract_address: *pragma_feeds_registry_address,
            entry_point_selector: selector!("get_all_feeds"),
            calldata: vec![],
        };

        let mut response = self.0.call(call, PENDING_BLOCK).await?;
        response.insert(0, Felt::from(1)); // to fit the format given in the function
        Ok(felt_vec_to_vec_string(&response)?)
    }
}
