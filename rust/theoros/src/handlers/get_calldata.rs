use axum::extract::{Query, State};
use axum::Json;
use pragma_feeds::{Feed, FeedType};
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToResponse, ToSchema};

use crate::errors::GetCalldataError;
use crate::extractors::PathExtractor;
use crate::types::pragma::calldata::{HyperlaneMessage, ValidatorSignature};
use crate::types::pragma::constants::HYPERLANE_VERSION;
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
    PathExtractor(feed_id): PathExtractor<String>,
    Query(_params): Query<GetCalldataQuery>,
) -> Result<Json<GetCalldataResponse>, GetCalldataError> {
    tracing::info!("Received get calldata request for feed: {feed_id}");

    // TODO: check that feed_id exists

    let feed: Feed = feed_id.parse().map_err(|_| GetCalldataError::InvalidFeedId)?;

    let checkpoints = state.storage.checkpoints().all().await;
    let events = state.storage.dispatch_events().all().await;

    let num_validators = checkpoints.keys().len();
    let signers = checkpoints
        .keys()
        .map(|validator_index| {
            // SAFE to unwrap because we just checked that the key exists
            let signed_checkpoint = checkpoints.get(validator_index).unwrap();
            let validator_index = 0; // TODO: fetch index from storage
            ValidatorSignature { validator_index, signature: signed_checkpoint.signature }
        })
        .collect();

    let hyperlane_message = HyperlaneMessage {
        hyperlane_version: HYPERLANE_VERSION,
        signers_len: num_validators as u8,
        signers,
        nonce: todo!(),
        timestamp: todo!(),
        emitter_chain_id: todo!(),
        emitter_address: todo!(),
        payload: todo!(),
    };

    Ok(Json(GetCalldataResponse::default()))
}
