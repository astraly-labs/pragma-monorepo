use axum::extract::{Query, State};
use axum::Json;
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToResponse, ToSchema};

use crate::errors::GetCalldataError;
use crate::extractors::PathExtractor;
use crate::hyperlane::calls::HyperlaneClient;
use crate::types::hyperlane::DispatchUpdate;
use crate::types::pragma::calldata::{AsCalldata, HyperlaneMessage, Payload};
use crate::types::pragma::constants::HYPERLANE_VERSION;
use crate::AppState;

use alloy::hex;
use alloy::primitives::Address;

#[derive(Default, Deserialize, IntoParams, ToSchema)]
pub struct GetCalldataQuery {}

#[derive(Debug, Default, Serialize, Deserialize, ToResponse, ToSchema)]
pub struct GetCalldataResponse {
    pub calldata: String,
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

    let stored_feed_ids = state.storage.feed_ids();
    if !stored_feed_ids.contains(&feed_id).await {
        return Err(GetCalldataError::FeedNotFound(feed_id));
    };

    let checkpoints = state.storage.checkpoints().all().await;

    let event = state
        .storage
        .dispatch_events()
        .get(&feed_id)
        .await
        .map_err(|_| GetCalldataError::FailedToRetrieveEvent)?
        .ok_or(GetCalldataError::FailedToRetrieveEvent)?;

    // TODO: store the evm compatible contract address somewhere
    let hyperlane_contract_address: Address = "0xb9aB8aDC69Ad3B96a8CdF5610e9bFEcc0415D662".parse::<Address>().unwrap();
    let num_validators = checkpoints.keys().len();

    // TODO: Create the Client before so we don't create it for each calls
    let client = HyperlaneClient::new(hyperlane_contract_address)
        .await
        .map_err(|_| GetCalldataError::FailedToCreateHyperlaneClient)?;
    let validators = client.get_validators().await.map_err(|_| GetCalldataError::FailedToFetchOnchainValidators)?;

    let signatures = state
        .storage
        .checkpoints()
        .get_validators_signatures(&validators)
        .await
        // TODO: Error
        .map_err(|_| GetCalldataError::ValidatorNotFound)?;

    let (_, checkpoint_infos) = checkpoints.iter().next().unwrap();

    let update = match event.update {
        DispatchUpdate::SpotMedian { update, feed_id: _ } => update,
    };

    let payload = Payload {
        checkpoint_root: checkpoint_infos.value.checkpoint.root.clone(),
        num_updates: 1,
        update_data_len: 1,
        proof_len: 0,
        proof: vec![],
        update_data: update.to_bytes(),
        feed_id,
        publish_time: update.metadata.timestamp,
    };

    let hyperlane_message = HyperlaneMessage {
        hyperlane_version: HYPERLANE_VERSION,
        signers_len: num_validators as u8,
        signatures,
        nonce: event.nonce,
        timestamp: update.metadata.timestamp,
        emitter_chain_id: event.emitter_chain_id,
        emitter_address: event.emitter_address,
        payload,
    };
    let response = GetCalldataResponse { calldata: hex::encode(hyperlane_message.as_bytes()) };

    Ok(Json(response))
}
