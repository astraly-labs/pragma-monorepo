pub mod hyperlane;

pub use hyperlane::*;
use starknet::core::types::Felt;

use std::collections::HashMap;

use alloy::hex::FromHex;
use alloy::primitives::Address;
use url::Url;

use crate::configs::evm_config::{EvmChainName, EvmConfig};

#[derive(Debug, Default, Clone)]
pub struct HyperlaneValidatorsMapping(HashMap<EvmChainName, Vec<Felt>>);

impl HyperlaneValidatorsMapping {
    pub async fn from_config(config: &EvmConfig) -> anyhow::Result<Self> {
        let mut contracts = HashMap::new();

        for (chain_name, chain_config) in config.chains() {
            let rpc_url: Url = chain_config.rpc_url.parse()?;
            let address = Address::from_hex(&chain_config.hyperlane_address)
                .map_err(|e| anyhow::anyhow!("Invalid hyperlane address for {chain_name:?}: {e}"))?;
            let rpc_client = HyperlaneClient::new(rpc_url, address).await;

            let validators = rpc_client.get_validators().await?;
            contracts.insert(*chain_name, validators);
        }

        Ok(Self(contracts))
    }

    pub fn get_validators(&self, chain_name: EvmChainName) -> Option<&Vec<Felt>> {
        self.0.get(&chain_name)
    }

    /// Get all configured chains names
    pub fn chain_names(&self) -> Vec<EvmChainName> {
        self.0.keys().cloned().collect()
    }

    /// Get the index of a validator for a chain
    pub fn validator_index(&self, chain_name: &EvmChainName, searched_validator: &Felt) -> Option<u8> {
        match self.0.get(chain_name) {
            Some(validators) => validators
                .iter()
                .position(|validator| validator == searched_validator)
                .and_then(|pos| pos.try_into().ok()),
            None => None,
        }
    }
}
