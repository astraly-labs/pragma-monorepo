use std::str::FromStr;

use anyhow::Context;
use apibara_sdk::Uri;
use starknet::core::types::Felt;
use url::Url;

use crate::configs::evm_config;

#[derive(clap::Parser, Debug)]
pub struct TheorosCli {
    #[clap(env = "APP_NAME", long, default_value = "theoros")]
    pub app_name: String,

    #[clap(env = "METRICS_PORT", long, default_value = "8080")]
    pub metrics_port: u16,

    #[clap(env = "MADARA_RPC_URL", long, value_parser = parse_url, default_value = "https://madara-pragma-prod.karnot.xyz/")]
    pub madara_rpc_url: Url,

    #[clap(env = "APIBARA_DNA_URL", long, value_parser = parse_uri, default_value = "https://devnet.pragma.a5a.ch")]
    pub apibara_dna_uri: Uri,

    #[clap(env = "APIBARA_API_KEY", long)]
    pub apibara_api_key: Option<String>,

    #[clap(env = "SERVER_HOST", long, default_value = "0.0.0.0")]
    pub server_host: String,

    #[clap(env = "SERVER_PORT", long, default_value = "3000")]
    pub server_port: u16,

    #[clap(env = "PRAGMA_FEEDS_REGISTRY_ADDRESS", long, value_parser = parse_felt)]
    pub pragma_feeds_registry_address: Felt,

    #[clap(env = "HYPERLANE_MAILBOX_ADDRESS", long, value_parser = parse_felt)]
    pub hyperlane_mailbox_address: Felt,

    #[clap(env = "HYPERLANE_MERKLE_TREE_HOOK_ADDRESS", long, value_parser = parse_felt)]
    pub hyperlane_merkle_tree_hook_address: Felt,

    #[clap(env = "HYPERLANE_VALIDATOR_ANNOUNCE_ADDRESS", long, value_parser = parse_felt)]
    pub hyperlane_validator_announce_address: Felt,

    #[clap(
        env = "EVM_CONFIG_PATH",
        long,
        alias = "evm_config_path",
        default_value = evm_config::DEFAULT_CONFIG_PATH,
        value_parser = parse_evm_config
    )]
    pub evm_config: evm_config::EvmConfig,
}

/// Parse a Felt.
pub fn parse_felt(s: &str) -> anyhow::Result<Felt> {
    Felt::from_hex(s).with_context(|| format!("Invalid felt format: {s}"))
}

/// Parse a string URL & returns it as [Url].
pub fn parse_url(s: &str) -> Result<Url, url::ParseError> {
    s.parse()
}

/// Parse a string URI & returns it as [Uri].
pub fn parse_uri(s: &str) -> anyhow::Result<Uri> {
    Uri::from_str(s).with_context(|| format!("Invalid URI format: {s}"))
}

/// Parses the EVM Config path & returns it as [evm_config::EvmConfig]
pub fn parse_evm_config(s: &str) -> anyhow::Result<evm_config::EvmConfig> {
    // Check if the file exists
    if !std::path::Path::new(s).exists() {
        anyhow::bail!("EVM config file not found at path: {}", s);
    }

    // Load and parse the config
    evm_config::EvmConfig::from_file(s).with_context(|| format!("Failed to load EVM config from path: {}", s))
}
