use std::collections::HashMap;
use std::fs;
use std::path::Path;
use std::str::FromStr;

use serde::{Deserialize, Serialize};
use thiserror::Error;

pub const DEFAULT_CONFIG_PATH: &str = "evm_config.yaml";

/// Supported Chain identifiers
// Must reflect the EVM chains here:
// https://github.com/astraly-labs/pragma-monorepo/blob/main/typescript/pragma-utils/src/chains.ts
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum EvmChainName {
    Mainnet,
    Sepolia,
    Holesky,
    Bsc,
    BscTestnet,
    Polygon,
    PolygonTestnet,
    PolygonZkEvm,
    Avalanche,
    Fantom,
    Arbitrum,
    Optimism,
    Base,
    Scroll,
    ScrollTestnet,
    ScrollSepoliaTestnet,
    ZircuitTestnet,
    PlumeTestnet,
    Worldchain,
    WorldchainTestnet,
    Zksync,
    ZksyncTestnet,
}

/// Configuration for a single chain
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct EvmChainConfig {
    pub rpc_url: String,
    pub hyperlane_address: String,
}

/// Main configuration structure
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct EvmConfig {
    #[serde(flatten)]
    chains: HashMap<EvmChainName, EvmChainConfig>,
}

#[derive(Error, Debug)]
pub enum ConfigError {
    #[error("Failed to read config file: {0}")]
    FileRead(#[from] std::io::Error),
    #[error("Failed to parse YAML: {0}")]
    YamlParse(#[from] serde_yaml::Error),
}

impl EvmConfig {
    /// Load configuration from a YAML file
    pub fn from_file<P: AsRef<Path>>(path: P) -> Result<Self, ConfigError> {
        let contents = fs::read_to_string(path)?;
        let config = serde_yaml::from_str(&contents)?;
        Ok(config)
    }

    /// Get configuration for a specific chain
    pub fn chain_config(&self, chain_name: EvmChainName) -> Option<&EvmChainConfig> {
        self.chains.get(&chain_name)
    }

    /// Get all configured chains
    pub fn chains(&self) -> &HashMap<EvmChainName, EvmChainConfig> {
        &self.chains
    }

    /// Get all configured chains names
    pub fn chain_names(&self) -> Vec<EvmChainName> {
        self.chains.keys().cloned().collect()
    }
}

#[derive(Error, Debug)]
#[error("Unknown chain name: {0}")]
pub struct ParseChainError(String);

impl FromStr for EvmChainName {
    type Err = ParseChainError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let chain_name = s.to_lowercase().replace('-', "_");
        match chain_name.as_str() {
            "mainnet" => Ok(Self::Mainnet),
            "sepolia" => Ok(Self::Sepolia),
            "holesky" => Ok(Self::Holesky),
            "bsc" => Ok(Self::Bsc),
            "bsc_testnet" => Ok(Self::BscTestnet),
            "polygon" => Ok(Self::Polygon),
            "polygon_testnet" => Ok(Self::PolygonTestnet),
            "polygon_zk_evm" => Ok(Self::PolygonZkEvm),
            "avalanche" => Ok(Self::Avalanche),
            "fantom" => Ok(Self::Fantom),
            "arbitrum" => Ok(Self::Arbitrum),
            "optimism" => Ok(Self::Optimism),
            "base" => Ok(Self::Base),
            "scroll" => Ok(Self::Scroll),
            "scroll_testnet" => Ok(Self::ScrollTestnet),
            "scroll_sepolia_testnet" => Ok(Self::ScrollSepoliaTestnet),
            "zircuit_testnet" => Ok(Self::ZircuitTestnet),
            "plume_testnet" => Ok(Self::PlumeTestnet),
            "worldchain" => Ok(Self::Worldchain),
            "worldchain_testnet" => Ok(Self::WorldchainTestnet),
            "zksync" => Ok(Self::Zksync),
            "zksync_testnet" => Ok(Self::ZksyncTestnet),
            _ => Err(ParseChainError(s.to_string())),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const EXAMPLE_CONFIG: &str = r#"
        zircuit_testnet:
            rpc_url: "https://zircuit1-testnet.p2pify.com"
            hyperlane_address: "0xb9aB8aDC69Ad3B96a8CdF5610e9bFEcc0415D662"
    "#;

    #[test]
    fn test_parse_config() {
        let config: EvmConfig = serde_yaml::from_str(EXAMPLE_CONFIG).unwrap();

        let zircuit_config = config.chain_config(EvmChainName::ZircuitTestnet).unwrap();
        assert_eq!(zircuit_config.rpc_url, "https://zircuit1-testnet.p2pify.com");
        assert_eq!(zircuit_config.hyperlane_address, "0xb9aB8aDC69Ad3B96a8CdF5610e9bFEcc0415D662");
    }
}
