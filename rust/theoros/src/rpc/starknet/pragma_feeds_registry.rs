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

        let raw_response = self.0.call(call, PENDING_BLOCK).await?;
        Ok(raw_response.iter().skip(1).map(|x| x.to_hex_string()).collect())
    }
}
