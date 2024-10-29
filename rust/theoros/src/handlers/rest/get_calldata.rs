use std::str::FromStr;

use alloy::hex;
use alloy::primitives::U256;
use axum::extract::{Query, State};
use axum::Json;
use serde::{Deserialize, Serialize};
use starknet::core::types::Felt;
use utoipa::{IntoParams, ToResponse, ToSchema};

use crate::configs::evm_config::EvmChainName;
use crate::constants::{HYPERLANE_VERSION, PRAGMA_MAJOR_VERSION, PRAGMA_MINOR_VERSION, TRAILING_HEADER_SIZE};
use crate::errors::GetCalldataError;
use crate::extractors::PathExtractor;
use crate::types::hyperlane::DispatchUpdate;
use crate::types::pragma::calldata::{AsCalldata, CalldataHeader, HyperlaneMessage, Payload};
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

    // TODO: Not correct atm - should reflect the actual validators that signed the index
    let _num_validators = checkpoints.keys().len();

    let event = state
        .storage
        .dispatch_events()
        .get(&feed_id)
        .await
        .map_err(|_| GetCalldataError::DispatchNotFound)?
        .ok_or(GetCalldataError::DispatchNotFound)?;

    let validators = state
        .hyperlane_validators_mapping
        .get_validators(chain_name)
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
        checkpoint_root: U256::from_str(&checkpoint_infos.value.checkpoint.root).unwrap(),
        num_updates: 1,
        update_data_len: 1,
        proof_len: 0,
        proof: vec![],
        update_data: update.to_bytes(),
        feed_id: U256::from_str(&feed_id).unwrap(),
        publish_time: update.metadata.timestamp,
    };

    let hyperlane_message = HyperlaneMessage {
        hyperlane_version: HYPERLANE_VERSION,
        signers_len: 1_u8, // TODO
        signatures: vec![*signatures.last().unwrap()],
        nonce: event.nonce,
        timestamp: update.metadata.timestamp,
        emitter_chain_id: event.emitter_chain_id,
        emitter_address: Felt::from_dec_str(&event.emitter_address).unwrap(),
        payload,
    };

    let calldata_header = CalldataHeader {
        major_version: PRAGMA_MAJOR_VERSION,
        minor_version: PRAGMA_MINOR_VERSION,
        trailing_header_size: TRAILING_HEADER_SIZE,
        hyperlane_msg_size: hyperlane_message.as_bytes().len().try_into().unwrap(),
        hyperlane_msg: hyperlane_message,
    };

    let response = GetCalldataResponse { calldata: hex::encode(calldata_header.as_bytes()) };
    tracing::info!("🌐 get_calldata - {:?}", started_at.elapsed());
    Ok(Json(response))
}
