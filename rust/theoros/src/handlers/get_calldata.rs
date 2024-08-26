use axum::extract::{Query, State};
use axum::Json;
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToResponse, ToSchema};

use crate::errors::GetCalldataError;
use crate::AppState;

#[derive(Default, Deserialize, IntoParams, ToSchema)]
pub struct GetCalldataQuery {}

#[derive(Debug, Default, Serialize, Deserialize, ToResponse, ToSchema)]
pub struct GetCalldataResponse {
    pub hash: String,
}

#[utoipa::path(
    get,
    // TODO: path
    path = "/v1/calldata",
    responses(
        (status = 200, description = "Get the calldata", body = [GetCalldataResponse])
    ),
    params(
        GetCalldataQuery
    ),
)]
pub async fn get_calldata(
    State(_state): State<AppState>,
    Query(_params): Query<GetCalldataQuery>,
) -> Result<Json<GetCalldataResponse>, GetCalldataError> {
    tracing::info!("Received get calldata request");
    Ok(Json(GetCalldataResponse::default()))
}
