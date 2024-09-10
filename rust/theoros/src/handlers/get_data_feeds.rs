use axum::extract::State;
use axum::Json;
use serde::{Deserialize, Serialize};
use utoipa::{ToResponse, ToSchema};

use crate::errors::GetDataFeedsError;
use crate::AppState;

#[derive(Debug, Default, Serialize, Deserialize, ToResponse, ToSchema)]
pub struct FeedId {
    r#id: String,
    name: String,
}

#[derive(Debug, Default, Serialize, Deserialize, ToResponse, ToSchema)]
pub struct GetDataFeedsResponse(pub Vec<FeedId>);

#[utoipa::path(
    get,
    path = "/v1/data_feeds",
    responses(
        (status = 200, description = "Get all the available data feeds", body = [GetDataFeedsResponse])
    ),
)]
pub async fn get_data_feeds(State(state): State<AppState>) -> Result<Json<GetDataFeedsResponse>, GetDataFeedsError> {
    tracing::info!("Received get calldata request");

    let _available_data_feeds = state.storage.data_feeds();

    // TODO: feeds
    let response = GetDataFeedsResponse(vec![]);
    Ok(Json(response))
}
