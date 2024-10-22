pub mod hyperlane;

pub use hyperlane::*;

use std::collections::HashMap;

use alloy::hex::FromHex;
use alloy::primitives::Address;
use url::Url;

use crate::configs::evm_config::{EvmChainName, EvmConfig};

#[derive(Debug, Clone)]
pub struct HyperlaneRpcs(HashMap<EvmChainName, HyperlaneClient>);

impl HyperlaneRpcs {
    pub async fn from_config(config: &EvmConfig) -> anyhow::Result<Self> {
        let mut contracts = HashMap::new();

        for (chain_name, chain_config) in config.chains() {
            let rpc_url: Url = chain_config.rpc_url.parse()?;
            let address = Address::from_hex(&chain_config.hyperlane_address)
                .map_err(|e| anyhow::anyhow!("Invalid hyperlane address for {chain_name:?}: {e}"))?;
            let rpc_client = HyperlaneClient::new(rpc_url, address).await?;
            contracts.insert(*chain_name, rpc_client);
        }

        Ok(Self(contracts))
    }

    pub fn get_rpc(&self, chain_name: EvmChainName) -> Option<&HyperlaneClient> {
        self.0.get(&chain_name)
    }

    pub fn rpcs(&self) -> &HashMap<EvmChainName, HyperlaneClient> {
        &self.0
    }

    /// Get all configured chains names
    pub fn chain_names(&self) -> Vec<EvmChainName> {
        self.0.keys().cloned().collect()
    }
}
