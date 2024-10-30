use std::str::FromStr;

use alloy::primitives::U256;
use starknet::core::types::Felt;

use crate::types::calldata::AsCalldata;
use crate::{
    configs::evm_config::EvmChainName,
    constants::{HYPERLANE_VERSION, PRAGMA_MAJOR_VERSION, PRAGMA_MINOR_VERSION, TRAILING_HEADER_SIZE},
    errors::GetCalldataError,
    storage::DispatchUpdateInfos,
    types::{
        calldata::{Calldata, HyperlaneMessage, Payload, ValidatorSignature},
        hyperlane::DispatchUpdate,
    },
    AppState,
};

pub async fn build_calldata(
    state: &AppState,
    chain_name: EvmChainName,
    feed_id: String,
) -> Result<Calldata, GetCalldataError> {
    let event: DispatchUpdateInfos = state
        .storage
        .dispatch_events()
        .get(&feed_id)
        .await
        .map_err(|_| GetCalldataError::DispatchNotFound)?
        .ok_or(GetCalldataError::DispatchNotFound)?;

    let validators = state
        .hyperlane_validators_mapping
        .get_validators(chain_name)
        .ok_or(GetCalldataError::ChainNotSupported(format!("{:?}", chain_name)))?;

    let checkpoints = state
        .storage
        .validators_checkpoints()
        .get_validators_signed_checkpoints(validators, event.message_id)
        .await
        .map_err(|_| GetCalldataError::ValidatorNotFound)?;

    // TODO: We only have one validator for now
    let checkpoint_infos = checkpoints.last().unwrap();

    let update = match event.update {
        DispatchUpdate::SpotMedian { update, feed_id: _ } => update,
    };

    let payload = Payload {
        checkpoint: checkpoint_infos.value.clone(),
        num_updates: 1,
        update_data_len: 1,
        proof_len: 0,
        proof: vec![],
        update_data: update.to_bytes(),
        // TODO: Store directly a U256.
        feed_id: U256::from_str(&feed_id).unwrap(),
        publish_time: update.metadata.timestamp,
    };

    let hyperlane_message = HyperlaneMessage {
        hyperlane_version: HYPERLANE_VERSION,
        // TODO: signers_len & signatures should work for multiple validators
        signers_len: 1_u8,
        signatures: vec![ValidatorSignature { validator_index: 0, signature: checkpoint_infos.signature }],
        nonce: event.nonce,
        timestamp: update.metadata.timestamp,
        emitter_chain_id: event.emitter_chain_id,
        // TODO: Store directly a Felt.
        emitter_address: Felt::from_dec_str(&event.emitter_address).unwrap(),
        payload,
    };

    let calldata = Calldata {
        major_version: PRAGMA_MAJOR_VERSION,
        minor_version: PRAGMA_MINOR_VERSION,
        trailing_header_size: TRAILING_HEADER_SIZE,
        hyperlane_msg_size: hyperlane_message.as_bytes().len().try_into().unwrap(),
        hyperlane_msg: hyperlane_message,
    };

    Ok(calldata)
}
