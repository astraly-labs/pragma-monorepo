use std::str::FromStr;

use alloy::hex;
use axum::extract::{Query, State};
use axum::Json;
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToResponse, ToSchema};

use crate::configs::evm_config::EvmChainName;
use crate::errors::GetCalldataError;
use crate::extractors::PathExtractor;
use crate::types::hyperlane::DispatchUpdate;
use crate::types::pragma::calldata::{AsCalldata, HyperlaneMessage, Payload};
use crate::types::pragma::constants::HYPERLANE_VERSION;
use crate::AppState;

#[derive(Default, Deserialize, IntoParams, ToSchema)]
pub struct GetCalldataQuery {}

#[derive(Debug, Default, Serialize, Deserialize, ToResponse, ToSchema)]
pub struct GetCalldataResponse {
    pub calldata: String,
}

#[utoipa::path(
    get,
    path = "/v1/calldata/{chain_name}/{feed_id}",
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
    PathExtractor(path_args): PathExtractor<(String, String)>,
    Query(_params): Query<GetCalldataQuery>,
) -> Result<Json<GetCalldataResponse>, GetCalldataError> {
    let started_at = std::time::Instant::now();
    let (raw_chain_name, feed_id) = path_args;
    let chain_name = EvmChainName::from_str(&raw_chain_name)
        .map_err(|_| GetCalldataError::ChainNotSupported(raw_chain_name.clone()))?;

    let stored_feed_ids = state.storage.feed_ids();
    if !stored_feed_ids.contains(&feed_id).await {
        return Err(GetCalldataError::FeedNotFound(feed_id));
    };

    let checkpoints = state.storage.checkpoints().all().await;
    let num_validators = checkpoints.keys().len();

    let event = state
        .storage
        .dispatch_events()
        .get(&feed_id)
        .await
        .map_err(|_| GetCalldataError::DispatchNotFound)?
        .ok_or(GetCalldataError::DispatchNotFound)?;

    let validators = state
        .hyperlane_validators_mapping
        .get_rpc(chain_name)
        .ok_or(GetCalldataError::ChainNotSupported(raw_chain_name))?;

    let signatures = state
        .storage
        .checkpoints()
        .get_validators_signatures(validators)
        .await
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
    tracing::info!("🌐 get_calldata - {:?}", started_at.elapsed());
    Ok(Json(response))
}
