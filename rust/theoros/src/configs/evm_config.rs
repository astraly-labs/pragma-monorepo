use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::Path;
use strum_macros::EnumString;
use thiserror::Error;

pub const DEFAULT_CONFIG_PATH: &str = "evm_config.yaml";

/// Supported Chain identifiers
// Must reflect the EVM chains here:
// https://github.com/astraly-labs/pragma-monorepo/blob/main/typescript/pragma-utils/src/chains.ts
#[derive(Debug, strum_macros::Display, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, EnumString)]
#[strum(serialize_all = "snake_case")]
#[serde(rename_all = "snake_case")]
#[strum(ascii_case_insensitive)]
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

    /// Get all configured chains
    pub fn chains(&self) -> &HashMap<EvmChainName, EvmChainConfig> {
        &self.chains
    }
}
