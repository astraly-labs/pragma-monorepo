use axum::{http::StatusCode, response::IntoResponse, Json};
use serde_json::json;
use utoipa::ToSchema;

#[derive(Debug, thiserror::Error, ToSchema)]
#[allow(unused)]
pub enum GetDataFeedsError {
    #[error("could not parse feed id: {0}")]
    ParsingFeedId(String),
    #[error("internal server error")]
    InternalServerError,
}

impl IntoResponse for GetDataFeedsError {
    fn into_response(self) -> axum::response::Response {
        let (status, err_msg) = match self {
            Self::ParsingFeedId(feed_id) => (StatusCode::PROCESSING, format!("Could not parse feed: {feed_id}")),
            _ => (StatusCode::INTERNAL_SERVER_ERROR, String::from("Internal server error")),
        };
        (status, Json(json!({"resource":"Calldata", "message": err_msg, "happened_at" : chrono::Utc::now() })))
            .into_response()
    }
}
