use axum::{http::StatusCode, response::IntoResponse, Json};
use serde_json::json;
use utoipa::ToSchema;

#[derive(Debug, thiserror::Error, ToSchema)]
#[allow(unused)]
pub enum GetDataFeedsError {
    #[error("internal server error")]
    InternalServerError,
    #[error("could not establish a connection with the database")]
    DatabaseConnection,
}

impl IntoResponse for GetDataFeedsError {
    fn into_response(self) -> axum::response::Response {
        let (status, err_msg) = match self {
            Self::DatabaseConnection => {
                (StatusCode::SERVICE_UNAVAILABLE, "Could not establish a connection with the Database".to_string())
            }
            _ => (StatusCode::INTERNAL_SERVER_ERROR, String::from("Internal server error")),
        };
        (status, Json(json!({"resource":"Calldata", "message": err_msg, "happened_at" : chrono::Utc::now() })))
            .into_response()
    }
}
