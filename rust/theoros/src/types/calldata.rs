use alloy::{primitives::U256, signers::Signature};
use anyhow::Context;
use pragma_utils::conversions::alloy::hex_str_to_u256;
use serde::{Deserialize, Serialize};
use starknet::core::types::Felt;
use std::str::FromStr;

use crate::{
    configs::evm_config::EvmChainName,
    constants::{HYPERLANE_VERSION, PRAGMA_MAJOR_VERSION, PRAGMA_MINOR_VERSION, TRAILING_HEADER_SIZE},
    types::hyperlane::{CheckpointWithMessageId, DispatchUpdate, DispatchUpdateInfos},
    types::state::AppState,
};

pub trait AsCalldata {
    fn as_bytes(&self) -> Vec<u8>;
}

#[derive(Clone, Eq, PartialEq, Debug, Serialize, Deserialize)]
pub struct Calldata {
    /// Major version of Pragma (should only be updated if there are breaking changes)
    pub major_version: u8,
    /// Minor version of Pragma (should be updated for non-breaking changes)
    pub minor_version: u8,
    /// Space reserved for future versions of Pragma
    pub trailing_header_size: u8,
    /// Size of the Hyperlane message in bytes
    pub hyperlane_msg_size: u16,
    /// Hyperlane message
    pub hyperlane_msg: HyperlaneMessage,
}

impl Calldata {
    // TODO: Only works for ONE validator for now.
    pub async fn build_from(state: &AppState, chain_name: EvmChainName, feed_id: String) -> anyhow::Result<Calldata> {
        let update_info: DispatchUpdateInfos = state
            .storage
            .latest_update_per_feed()
            .get(&hex_str_to_u256(&feed_id).unwrap())
            .await?
            .context("No update found")?;

        let validators =
            state.hyperlane_validators_mapping.get_validators(chain_name).context("No validators found")?;

        let checkpoints = state.storage.signed_checkpoints().get(validators, update_info.nonce).await;

        let checkpoint_infos = checkpoints.last().unwrap();

        let update = match update_info.update {
            DispatchUpdate::SpotMedian { update, feed_id: _ } => update,
        };

        let payload = Payload {
            checkpoint: checkpoint_infos.value.clone(),
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
            signers_len: 1_u8,
            signatures: vec![ValidatorSignature { validator_index: 0, signature: checkpoint_infos.signature }],
            nonce: update_info.nonce,
            timestamp: update.metadata.timestamp,
            emitter_chain_id: update_info.emitter_chain_id,
            emitter_address: update_info.emitter_address,
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
}

impl AsCalldata for Calldata {
    fn as_bytes(&self) -> Vec<u8> {
        let mut bytes = vec![self.major_version, self.minor_version, self.trailing_header_size];
        bytes.extend_from_slice(&self.hyperlane_msg_size.to_be_bytes());
        bytes.extend_from_slice(&self.hyperlane_msg.as_bytes());
        bytes
    }
}

#[derive(Clone, Eq, PartialEq, Debug, Serialize, Deserialize)]
pub struct HyperlaneMessage {
    /// Version of the Hyperlane protocol
    pub hyperlane_version: u8,
    /// Number of signers
    pub signers_len: u8,
    /// List of signatures
    pub signatures: Vec<ValidatorSignature>,
    pub nonce: u32,
    pub timestamp: u64,
    /// Chain ID of the emitter (pragma chain id)
    pub emitter_chain_id: u32,
    /// Address of the emitter (pragma chain mailbox address)
    pub emitter_address: Felt,
    pub payload: Payload,
}

impl AsCalldata for HyperlaneMessage {
    fn as_bytes(&self) -> Vec<u8> {
        let mut bytes = vec![self.hyperlane_version, self.signers_len];
        for signer in &self.signatures {
            bytes.push(signer.validator_index);
            bytes.extend_from_slice(&signer.signature.as_bytes());
        }
        bytes.extend_from_slice(&self.nonce.to_be_bytes());
        bytes.extend_from_slice(&self.timestamp.to_be_bytes());
        bytes.extend_from_slice(&self.emitter_chain_id.to_be_bytes());
        bytes.extend_from_slice(&self.emitter_address.to_bytes_be());
        bytes.extend_from_slice(&self.payload.as_bytes());
        bytes
    }
}

#[derive(Copy, Clone, Eq, PartialEq, Debug, Serialize, Deserialize)]
pub struct ValidatorSignature {
    /// Index of the validator in the solidity mapping
    pub validator_index: u8,
    pub signature: Signature,
}

impl AsCalldata for ValidatorSignature {
    fn as_bytes(&self) -> Vec<u8> {
        let mut bytes = vec![self.validator_index];
        bytes.extend_from_slice(&self.signature.as_bytes());
        bytes
    }
}

#[derive(Clone, Eq, PartialEq, Debug, Serialize, Deserialize)]
pub struct Payload {
    pub checkpoint: CheckpointWithMessageId,
    /// Number of updates
    pub num_updates: u8,
    pub update_data_len: u16,
    /// Length of the proof
    #[serde(skip)]
    pub proof_len: u16,
    #[serde(skip)]
    pub proof: Vec<String>,
    #[serde(skip)]
    pub update_data: Vec<u8>,
    /// The id associated to the feed to be updated
    pub feed_id: U256,
    pub publish_time: u64,
}

impl AsCalldata for Payload {
    fn as_bytes(&self) -> Vec<u8> {
        let mut bytes = vec![];
        bytes.extend_from_slice(self.checkpoint.checkpoint.merkle_tree_hook_address.to_be_bytes::<32>().as_slice());
        let root: [u8; 32] = U256::from_str(&self.checkpoint.checkpoint.root).unwrap().to_be_bytes();
        bytes.extend_from_slice(root.as_slice());
        bytes.extend_from_slice(self.checkpoint.checkpoint.index.to_be_bytes().as_slice());
        bytes.extend_from_slice(self.checkpoint.message_id.to_be_bytes::<32>().as_slice());
        bytes.push(self.num_updates);
        bytes.extend_from_slice(&self.update_data_len.to_be_bytes());
        bytes.extend_from_slice(&self.proof_len.to_be_bytes());
        for proof in &self.proof {
            bytes.extend_from_slice(proof.as_bytes());
        }
        bytes.extend_from_slice(&self.update_data);
        let feed_id: [u8; 32] = self.feed_id.to_be_bytes();
        bytes.extend_from_slice(feed_id.as_slice());
        bytes.extend_from_slice(&self.publish_time.to_be_bytes());
        bytes
    }
}
