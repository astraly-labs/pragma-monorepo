use axum::extract::State;
use axum::Json;
use pragma_utils::feeds::Feed;
use serde::{Deserialize, Serialize};
use utoipa::{ToResponse, ToSchema};

use crate::errors::GetDataFeedsError;
use crate::AppState;

#[derive(Debug, Default, Serialize, Deserialize, ToResponse, ToSchema)]
pub struct GetDataFeedsResponse(pub Vec<Feed>);

#[utoipa::path(
    get,
    path = "/v1/data_feeds",
    responses(
        (status = 200, description = "Get all the available feed ids", body = [GetDataFeedsResponse])
    ),
)]
pub async fn get_data_feeds(State(state): State<AppState>) -> Result<Json<GetDataFeedsResponse>, GetDataFeedsError> {
    tracing::info!("Received get all data feeds request");

    let stored_feed_ids = state.storage.data_feeds();

    let mut feeds = Vec::with_capacity(stored_feed_ids.len());
    for feed_id in stored_feed_ids {
        let feed = feed_id.parse().map_err(|_| GetDataFeedsError::ParsingFeedId(feed_id.clone()))?;
        feeds.push(feed);
    }

    let response = GetDataFeedsResponse(feeds);
    Ok(Json(response))
}
