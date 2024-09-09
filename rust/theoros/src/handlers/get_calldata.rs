use axum::extract::{Query, State};
use axum::Json;
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToResponse, ToSchema};

use crate::errors::GetCalldataError;
use crate::extractors::PathExtractor;
use crate::AppState;

#[derive(Default, Deserialize, IntoParams, ToSchema)]
pub struct GetCalldataQuery {}

#[derive(Debug, Default, Serialize, Deserialize, ToResponse, ToSchema)]
pub struct GetCalldataResponse {
    pub hash: String,
}

#[utoipa::path(
    get,
    path = "/v1/calldata/{data_feed_id}",
    responses(
        (
            status = 200,
            description = "Constructs the calldata used to update the data feed id specified",
            body = [GetCalldataResponse]
        )
    ),
    params(
        GetCalldataQuery
    ),
)]
pub async fn get_calldata(
    State(_state): State<AppState>,
    PathExtractor(data_feed_id): PathExtractor<String>,
    Query(_params): Query<GetCalldataQuery>,
) -> Result<Json<GetCalldataResponse>, GetCalldataError> {
    tracing::info!("Received get calldata request for feed: {data_feed_id}");
    Ok(Json(GetCalldataResponse::default()))
}
