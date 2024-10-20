pub mod hyperlane;
pub mod pragma_feeds_registry;

pub use hyperlane::*;
pub use pragma_feeds_registry::*;

use starknet::providers::{jsonrpc::HttpTransport, JsonRpcClient};
use url::Url;

pub struct StarknetRpc(JsonRpcClient<HttpTransport>);

impl StarknetRpc {
    pub fn new(rpc_url: Url) -> Self {
        Self(JsonRpcClient::new(HttpTransport::new(rpc_url)))
    }
}
