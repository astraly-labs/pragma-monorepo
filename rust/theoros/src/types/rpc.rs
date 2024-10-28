use serde::{Deserialize, Serialize};
use utoipa::ToSchema;

pub type RpcDataFeedIdentifier = String;

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct RpcDataFeed {
    pub feed_id: RpcDataFeedIdentifier,
    /// The calldata binary represented as a hex string.
    #[serde(skip_serializing_if = "Option::is_none")]
    #[schema(value_type = Option<String>)]
    pub calldata: Option<String>,
}
