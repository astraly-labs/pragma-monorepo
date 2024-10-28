use std::str::FromStr;

use alloy::hex;
use axum::extract::{Query, State};
use axum::Json;
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToResponse, ToSchema};

use crate::configs::evm_config::EvmChainName;
use crate::errors::GetCalldataError;
use crate::extractors::PathExtractor;
use crate::types::hyperlane::{DispatchUpdate, SpotMedianUpdate};
use crate::types::pragma::calldata::{AsCalldata, FeedUpdate, HyperlaneMessage, Payload};
use crate::types::pragma::constants::HYPERLANE_VERSION;
use crate::AppState;

#[derive(Default, Deserialize, IntoParams, ToSchema)]
pub struct GetCalldataQuery {
    ids: Vec<String>,
}

#[derive(Debug, Default, Serialize, Deserialize, ToResponse, ToSchema)]
pub struct GetCalldataResponse {
    pub calldata: String,
}

#[utoipa::path(
    get,
    path = "/v1/calldata/{chain_name}",
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
    PathExtractor(path_arg): PathExtractor<String>,
    Query(params): Query<GetCalldataQuery>,
) -> Result<Json<GetCalldataResponse>, GetCalldataError> {
    let started_at = std::time::Instant::now();
    let raw_chain_name = path_arg;
    let feed_ids = params.ids;
    let chain_name = EvmChainName::from_str(&raw_chain_name)
        .map_err(|_| GetCalldataError::ChainNotSupported(raw_chain_name.clone()))?;

    let stored_feed_ids = state.storage.feed_ids();

    match stored_feed_ids.contains_vec(&feed_ids).await {
        Some(missing_id) => return Err(GetCalldataError::FeedNotFound(missing_id)),
        None => {}
    }

    let checkpoints = state.storage.checkpoints().all().await;
    let num_validators = checkpoints.keys().len();

    let (events, _) =
        state.storage.dispatch_events().get_vec(&feed_ids).await.map_err(|_| GetCalldataError::DispatchNotFound)?;

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

    let updates = events
        .iter()
        .map(|event| match &event.update {
            DispatchUpdate::SpotMedian { update, feed_id } => (update, feed_id),
        })
        .collect::<Vec<(&SpotMedianUpdate, &String)>>();

    let payload = Payload {
        checkpoint_root: checkpoint_infos.value.checkpoint.root.clone(),
        num_updates: feed_ids.len() as u8,
        update_data_len: 1,
        proof_len: 0,
        proof: vec![],
        feed_updates: updates
            .into_iter()
            .map(|(update, feed_id)| FeedUpdate {
                update_data: update.to_bytes(),
                feed_id: feed_id.to_string(),
                publish_time: update.metadata.timestamp,
            })
            .collect(),
    };

    let first_event = events.first().unwrap();
    let nonce = first_event.nonce;
    let emitter_chain_id = first_event.emitter_chain_id;
    let emitter_address = first_event.emitter_address.clone();

    let hyperlane_message = HyperlaneMessage {
        hyperlane_version: HYPERLANE_VERSION,
        signers_len: num_validators as u8,
        signatures,
        nonce,
        timestamp: chrono::Utc::now().timestamp() as u64,
        emitter_chain_id,
        emitter_address,
        payload,
    };
    let response = GetCalldataResponse { calldata: hex::encode(hyperlane_message.as_bytes()) };
    tracing::info!("🌐 get_calldata - {:?}", started_at.elapsed());
    Ok(Json(response))
}
