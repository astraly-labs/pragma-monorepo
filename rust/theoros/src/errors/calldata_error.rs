use axum::{http::StatusCode, response::IntoResponse, Json};
use serde_json::json;
use utoipa::ToSchema;

#[derive(Debug, thiserror::Error, ToSchema)]
#[allow(unused)]
pub enum GetCalldataError {
    #[error("internal server error")]
    InternalServerError,
    #[error("could not establish a connection with the database")]
    DatabaseConnection,
    #[error("invalid feed id")]
    InvalidFeedId,
    #[error("could not find any dispatch event")]
    DispatchNotFound,
    #[error("Feed with ID '{0}' not found")]
    FeedNotFound(String),
    #[error("Fail to create hyperlane client")]
    FailedToCreateHyperlaneClient,
    #[error("Fail to fetch onchain validators")]
    FailedToFetchOnchainValidators,
    #[error("Validator not found in validators list")]
    ValidatorNotFound,
    #[error("The chain '{0}' is not supported")]
    ChainNotSupported(String),
    #[error("Error while building the calldata: {0}")]
    CalldataError(String),
}

impl IntoResponse for GetCalldataError {
    fn into_response(self) -> axum::response::Response {
        let (status, err_msg) = match self {
            Self::DatabaseConnection => {
                (StatusCode::SERVICE_UNAVAILABLE, "Could not establish a connection with the Database".to_string())
            }
            Self::FeedNotFound(feed_id) => {
                (StatusCode::NOT_FOUND, format!("Feed ID \"{}\" is not registered", feed_id))
            }
            Self::DispatchNotFound => {
                (StatusCode::NOT_FOUND, "Could not find any Dispatch event for the provided Feed ID".into())
            }
            _ => (StatusCode::INTERNAL_SERVER_ERROR, String::from("Internal server error")),
        };
        (status, Json(json!({"resource":"Calldata", "message": err_msg, "happened_at" : chrono::Utc::now() })))
            .into_response()
    }
}
