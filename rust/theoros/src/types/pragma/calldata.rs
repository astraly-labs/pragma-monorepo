
use alloy::signers::Signature;
use starknet::core::types::U256;

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
    pub hyperlane_msg: HyperlaneMessage

}
#[derive(Clone, Eq, PartialEq, Debug)]
pub struct HyperlaneMessage {
    /// Version of the Hyperlane protocol
    pub hyperlane_version: u8, 
    /// Number of signers
    pub signers_len: u8, 
    /// List of signatures 
    pub signers:Vec<ValidatorSignature> , 
    pub nonce: u32, 
    pub timestamp : u64, 
    /// Chain ID of the emitter (pragma chain id)
    pub emitter_chain_id: u16, 
    /// Address of the emitter (pragma chain mailbox address)
    pub emitter_address: String, 
    pub payload: Payload
}
#[derive(Copy, Clone, Eq, PartialEq, Debug)]
pub struct ValidatorSignature {
    /// Index of the validator in the solidity mapping
    pub validator_index: u8, 
    pub signature: Signature
}
#[derive(Clone, Eq, PartialEq, Debug)]
pub struct Payload {
    /// Merkle root of the checkpoint (computed by the merkle tree hook)
    pub checkpoint_root: String, 
    /// N
    pub num_updates: u8, 

    pub update_data_len: u16, 
    /// Length of the proof
    pub proof_len: u16, 

    pub proof : Vec<String>, 

    pub update_data: Vec<u8>,
    /// The id associated to the feed to be updated
    pub feed_id: String, 

    pub publish_time: u64

}

