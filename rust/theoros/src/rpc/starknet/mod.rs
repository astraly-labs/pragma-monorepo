pub mod hyperlane;
pub mod pragma_feeds_registry;

pub use hyperlane::*;
pub use pragma_feeds_registry::*;

use anyhow::Context;
use starknet::providers::{jsonrpc::HttpTransport, JsonRpcClient, Provider};
use url::Url;

pub struct StarknetRpc(JsonRpcClient<HttpTransport>);

impl StarknetRpc {
    pub fn new(rpc_url: Url) -> Self {
        Self(JsonRpcClient::new(HttpTransport::new(rpc_url)))
    }

    pub async fn block_number(&self) -> anyhow::Result<u64> {
        self.0.block_number().await.context("Fetching block number")
    }
}
