use alloy::signers::Signature;

pub trait AsCalldata {
    fn as_bytes(&self) -> Vec<u8>;
}

#[derive(Clone, Eq, PartialEq, Debug)]
pub struct CalldataHeader {
    /// Major version of Pragma (should only be updated if there are breaking changes)
    pub major_version: u8,
    /// Minor version of Pragma (should be updated for non-breaking changes)
    pub minor_version: u8,
    /// Space reserved for future versions of Pragma
    pub trailing_header_size: u8,
    /// Size of the Hyperlane message in bytes
    pub hyperlane_msg_size: u8,
    /// Hyperlane message
    pub hyperlane_msg: HyperlaneMessage,
}

impl AsCalldata for CalldataHeader {
    fn as_bytes(&self) -> Vec<u8> {
        let mut bytes =
            vec![self.major_version, self.minor_version, self.trailing_header_size, self.hyperlane_msg_size];
        bytes.extend_from_slice(&self.hyperlane_msg.as_bytes());
        bytes
    }
}

#[derive(Clone, Eq, PartialEq, Debug)]
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
    pub emitter_address: String,
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
        bytes.extend_from_slice(self.emitter_address.as_bytes());
        bytes.extend_from_slice(&self.payload.as_bytes());
        bytes
    }
}

#[derive(Copy, Clone, Eq, PartialEq, Debug)]
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

#[derive(Clone, Eq, PartialEq, Debug)]
pub struct Payload {
    /// Merkle root of the checkpoint (computed by the merkle tree hook)
    pub checkpoint_root: String,
    /// Number of updates
    pub num_updates: u8,

    pub update_data_len: u16,
    /// Length of the proof
    pub proof_len: u16,

    pub proof: Vec<String>,

    pub update_data: Vec<u8>,
    /// The id associated to the feed to be updated
    pub feed_id: String,

    pub publish_time: u64,
}

// TODO: these should be tested and follow the abi.encodePacked spec

impl AsCalldata for Payload {
    fn as_bytes(&self) -> Vec<u8> {
        let mut bytes = vec![];
        bytes.extend_from_slice(self.checkpoint_root.as_bytes());
        bytes.push(self.num_updates);
        bytes.extend_from_slice(&self.update_data_len.to_be_bytes());
        bytes.extend_from_slice(&self.proof_len.to_be_bytes());
        for proof in &self.proof {
            bytes.extend_from_slice(proof.as_bytes());
        }
        bytes.extend_from_slice(&self.update_data);
        bytes.extend_from_slice(self.feed_id.as_bytes());
        bytes.extend_from_slice(&self.publish_time.to_be_bytes());
        bytes
    }
}
