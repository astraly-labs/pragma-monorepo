use std::str::FromStr;

use alloy::hex;
use axum::{
    extract::{Query, State},
    Json,
};
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToResponse, ToSchema};

use crate::{
    configs::evm_config::EvmChainName,
    errors::GetCalldataError,
    types::calldata::{AsCalldata, Calldata},
    AppState,
};

#[derive(Deserialize, IntoParams, ToSchema)]
pub struct GetCalldataQuery {
    pub chain: String,
    #[serde(deserialize_with = "deserialize_feed_ids")]
    pub feed_ids: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize, ToResponse, ToSchema)]
pub struct GetCalldataResponse {
    pub feed_id: String,
    pub encoded_calldata: String,
}

#[utoipa::path(
    get,
    path = "/v1/calldata",
    params(
        GetCalldataQuery
    ),
    responses(
        (
            status = 200,
            description = "Constructs the calldata used to update the specified feed IDs",
            body = [GetCalldataResponse]
        ),
        (
            status = 404,
            description = "Unknown Feed ID",
            body = GetCalldataError
        )
    ),
)]
pub async fn get_calldata(
    State(state): State<AppState>,
    Query(params): Query<GetCalldataQuery>,
) -> Result<Json<Vec<GetCalldataResponse>>, GetCalldataError> {
    let started_at = std::time::Instant::now();

    let chain_name =
        EvmChainName::from_str(&params.chain).map_err(|_| GetCalldataError::ChainNotSupported(params.chain.clone()))?;

    let stored_feed_ids = state.storage.feed_ids();

    // Check if all requested feed IDs are supported.
    if let Some(missing_id) = stored_feed_ids.contains_vec(&params.feed_ids).await {
        return Err(GetCalldataError::FeedNotFound(missing_id));
    }

    // Build calldata for each feed ID.
    let mut responses = Vec::with_capacity(params.feed_ids.len());
    for feed_id in &params.feed_ids {
        let calldata = Calldata::build_from(&state, chain_name, feed_id.clone())
            .await
            .map_err(|e| GetCalldataError::CalldataError(e.to_string()))?;

        let response =
            GetCalldataResponse { feed_id: feed_id.clone(), encoded_calldata: hex::encode(calldata.as_bytes()) };
        responses.push(response);
    }

    tracing::info!("🌐 get_calldata - {:?}", started_at.elapsed());
    Ok(Json(responses))
}

/// Deserialize a list of feed ids "A, B, C" into a Vec<String> = [A, B, C].
fn deserialize_feed_ids<'de, D>(deserializer: D) -> Result<Vec<String>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let s: String = String::deserialize(deserializer)?;
    Ok(s.split(',').map(|s| s.trim().to_string()).collect())
}
