use axum::extract::{Query, State};
use axum::Json;
use pragma_feeds::{Feed, FeedType};
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToResponse, ToSchema};

use crate::errors::GetCalldataError;
use crate::extractors::PathExtractor;
use crate::types::hyperlane::DispatchUpdate;
use crate::types::pragma::calldata::{HyperlaneMessage, Payload, ValidatorSignature};
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
    let event = state
        .storage
        .dispatch_events()
        .get(&feed_id)
        .await
        .map_err(|_| GetCalldataError::FailedToRetrieveEvent)?
        .unwrap();

    let num_validators = checkpoints.keys().len();
    let signers: Vec<ValidatorSignature> = checkpoints
        .iter()
        .map(|((validator_index, _), signed_checkpoint)| {
            ValidatorSignature {
                validator_index: 0, // TODO: fetch index from storage
                signature: signed_checkpoint.signature.clone(),
            }
        })
        .collect();

    let (first_validator, checkpoint_infos) = checkpoints.iter().next().unwrap();

    let update = match event.update {
        DispatchUpdate::SpotMedian { update, feed_id } => update,
        _ => unimplemented!("TODO: Implement the other updates"),
    };

    let payload = Payload {
        checkpoint_root: checkpoint_infos.value.checkpoint.root.clone(),
        num_updates: 1,
        update_data_len: 1,
        proof_len: todo!(),
        proof: todo!(),
        update_data: update.to_bytes(),
        feed_id,
        publish_time: update.metadata.timestamp,
    };

    let hyperlane_message = HyperlaneMessage {
        hyperlane_version: HYPERLANE_VERSION,
        signers_len: num_validators as u8,
        signers,
        nonce: event.nonce,
        timestamp: update.metadata.timestamp,
        emitter_chain_id: event.emitter_chain_id,
        emitter_address: event.emitter_address,
        payload,
    };

    Ok(Json(GetCalldataResponse::default()))
}
