use axum::extract::{Query, State};
use axum::Json;
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToResponse, ToSchema};

use crate::errors::GetDataFeedsError;
use crate::AppState;

#[derive(Default, Deserialize, IntoParams, ToSchema)]
pub struct GetDataFeedsQuery {}

#[derive(Debug, Default, Serialize, Deserialize, ToResponse, ToSchema)]
pub struct GetDataFeedsResponse(pub Vec<String>);

#[utoipa::path(
    get,
    // TODO: path
    path = "/v1/calldata",
    responses(
        (status = 200, description = "Get all the available data feeds", body = [GetDataFeedsResponse])
    ),
    params(
        GetDataFeedsQuery
    ),
)]
pub async fn get_data_feeds(
    State(_state): State<AppState>,
    Query(_params): Query<GetDataFeedsQuery>,
) -> Result<Json<GetDataFeedsResponse>, GetDataFeedsError> {
    tracing::info!("Received get calldata request");
    Ok(Json(GetDataFeedsResponse::default()))
}
