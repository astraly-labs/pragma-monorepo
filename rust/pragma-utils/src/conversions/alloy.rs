use alloy::primitives::U256;
use anyhow::Context;

pub fn hex_str_to_u256(s: &str) -> anyhow::Result<U256> {
    let s = if s.starts_with("0x") { s.replace("0x", "").to_string() } else { s.to_string() };
    U256::from_str_radix(&s, 16).context("Could not convert to U256")
}
