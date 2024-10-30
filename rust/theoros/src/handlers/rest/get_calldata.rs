use std::str::FromStr;

use alloy::hex;
use axum::extract::{Query, State};
use axum::Json;
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToResponse, ToSchema};

use crate::configs::evm_config::EvmChainName;
use crate::errors::GetCalldataError;
use crate::extractors::PathExtractor;
use crate::types::calldata::{AsCalldata, Calldata};
use crate::AppState;

#[derive(Default, Deserialize, IntoParams, ToSchema)]
pub struct GetCalldataQuery {}

#[derive(Debug, Serialize, Deserialize, ToResponse, ToSchema)]
pub struct GetCalldataResponse {
    pub calldata: Calldata,
    pub encoded_calldata: String,
}

#[utoipa::path(
    get,
    path = "/v1/calldata/{chain_name}/{feed_id}",
    responses(
        (
            status = 200,
            description = "Constructs the calldata used to update the feed id specified",
            body = [GetCalldataResponse]
        ),
        (
            status = 404,
            description = "Unknown Feed Id",
            body = [GetCalldataError]
        )
    ),
    params(
        GetCalldataQuery
    ),
)]
pub async fn get_calldata(
    State(state): State<AppState>,
    PathExtractor(path_args): PathExtractor<(String, String)>,
    Query(_params): Query<GetCalldataQuery>,
) -> Result<Json<GetCalldataResponse>, GetCalldataError> {
    let started_at = std::time::Instant::now();
    let (raw_chain_name, feed_id) = path_args;
    let chain_name = EvmChainName::from_str(&raw_chain_name)
        .map_err(|_| GetCalldataError::ChainNotSupported(raw_chain_name.clone()))?;

    let stored_feed_ids = state.storage.feed_ids();
    if !stored_feed_ids.contains(&feed_id).await {
        return Err(GetCalldataError::FeedNotFound(feed_id));
    };

    let calldata = Calldata::build_from(&state, chain_name, feed_id).await?;

    let response =
        GetCalldataResponse { calldata: calldata.clone(), encoded_calldata: hex::encode(calldata.as_bytes()) };
    tracing::info!("🌐 get_calldata - {:?}", started_at.elapsed());
    Ok(Json(response))
}
