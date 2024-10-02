use axum::extract::{Query, State};
use axum::Json;
use pragma_feeds::{Feed, FeedType};
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToResponse, ToSchema};

use crate::errors::GetCalldataError;
use crate::extractors::PathExtractor;
use crate::AppState;

#[derive(Default, Deserialize, IntoParams, ToSchema)]
pub struct GetCalldataQuery {}

#[derive(Debug, Default, Serialize, Deserialize, ToResponse, ToSchema)]
pub struct GetCalldataResponse {
    pub calldata: Vec<String>,
}

#[utoipa::path(
    get,
    path = "/v1/calldata/{feed_id}",
    responses(
        (
            status = 200,
            description = "Constructs the calldata used to update the feed id specified",
            body = [GetCalldataResponse]
        )
    ),
    params(
        GetCalldataQuery
    ),
)]
pub async fn get_calldata(
    State(state): State<AppState>,
    PathExtractor(feed_id): PathExtractor<String>,
    Query(_params): Query<GetCalldataQuery>,
) -> Result<Json<GetCalldataResponse>, GetCalldataError> {
    tracing::info!("Received get calldata request for feed: {feed_id}");

    // TODO: check that feed_id exists

    let feed: Feed = feed_id.parse().map_err(|_| GetCalldataError::InvalidFeedId)?;

    let checkpoints = state.storage.checkpoints().all().await;
    let events = state.storage.dispatch_events().all().await;



    Ok(Json(GetCalldataResponse::default()))
}


