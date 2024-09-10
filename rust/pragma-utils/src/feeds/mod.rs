//! This module provides functionality for parsing and representing Pragma data feeds.
//!
//! # Feed Encoding
//!
//! Feeds are encoded as hexadecimal strings with the following structure:
//!
//! ```text
//! [ASSET_CLASS] [FEED_TYPE] [PAIR_ID]
//! ```
//!
//! - `ASSET_CLASS`: 1 byte representing the asset class (e.g., 1 for Crypto)
//! - `FEED_TYPE`: 2 bytes representing the type of feed (e.g., 534d for Spot Median)
//! - `PAIR_ID`: 32 bytes representing the trading pair (e.g., "BTC/USD")
//!   If the provided pair ID is shorter than 32 bytes, it will be right-padded with zeros.
//!
//! Total length: Always 35 bytes (70 hexadecimal characters)
//!
//! Example feed ID: `0x01534d4254432f555344` (will be padded to 35 bytes internally)
//!
//! # Parsing
//!
//! Feeds can be parsed from hexadecimal strings (with or without a "0x" prefix) using the `FromStr` trait.
//! The `Feed` struct represents a parsed feed, containing the asset class, feed type, and pair ID.
//!
//! # Asset Classes
//!
//! Currently, only the Crypto asset class is supported (represented by the value 1).
//!
//! # Feed Types
//!
//! Supported feed types include:
//! - Spot Median (21325)
//! - TWAP (21591)
//! - Realized Volatility (21078)
//! - Options (20304)
//! - Perp (20560)
use std::convert::TryFrom;
use std::str::FromStr;

use anyhow::{anyhow, bail, Context};
use hex;
use strum_macros::{Display, EnumString};

#[derive(Debug, PartialEq)]
pub struct Feed {
    pub asset_class: AssetClass,
    pub feed_type: FeedType,
    pub pair_id: String,
}

#[derive(Debug, PartialEq, Display, EnumString)]
pub enum AssetClass {
    Crypto = 1,
}

impl TryFrom<u8> for AssetClass {
    type Error = anyhow::Error;

    fn try_from(value: u8) -> anyhow::Result<Self> {
        match value {
            1 => Ok(AssetClass::Crypto),
            _ => Err(anyhow!("Unknown asset class: {}", value)),
        }
    }
}

#[derive(Debug, PartialEq, Display, EnumString)]
pub enum FeedType {
    #[strum(serialize = "Spot Median")]
    SpotMedian = 21325,
    TWAP = 21591,
    #[strum(serialize = "Realized Volatility")]
    RealizedVolatility = 21078,
    Options = 20304,
    Perp = 20560,
}

impl TryFrom<u16> for FeedType {
    type Error = anyhow::Error;

    fn try_from(value: u16) -> anyhow::Result<Self> {
        match value {
            21325 => Ok(FeedType::SpotMedian),
            21591 => Ok(FeedType::TWAP),
            21078 => Ok(FeedType::RealizedVolatility),
            20304 => Ok(FeedType::Options),
            20560 => Ok(FeedType::Perp),
            _ => Err(anyhow!("Unknown feed type: {}", value)),
        }
    }
}

impl FromStr for Feed {
    type Err = anyhow::Error;

    fn from_str(feed_id: &str) -> anyhow::Result<Self> {
        let feed_id = feed_id.strip_prefix("0x").unwrap_or(feed_id);
        let mut bytes = hex::decode(feed_id)?;

        if bytes.len() < 3 {
            bail!("Feed ID is too short");
        }

        if bytes.len() > 35 {
            bail!("Feed ID is too long");
        }

        // Pad the bytes to 35 if necessary
        bytes.resize(35, 0);

        let asset_class = AssetClass::try_from(bytes[0])?;
        let feed_type = FeedType::try_from(u16::from_be_bytes([bytes[1], bytes[2]]))?;

        let pair_id = String::from_utf8(bytes[3..].to_vec())
            .context("Invalid UTF-8 sequence for pair_id")?
            .trim_end_matches('\0')
            .to_string();

        if pair_id.is_empty() {
            bail!("Empty pair ID");
        }

        Ok(Feed { asset_class, feed_type, pair_id })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_feed_from_str() {
        let feed_id = "0x01534d4254432f555344";
        let result: Feed = feed_id.parse().unwrap();

        assert_eq!(result.asset_class, AssetClass::Crypto);
        assert_eq!(result.feed_type, FeedType::SpotMedian);
        assert_eq!(result.pair_id, "BTC/USD");
    }

    #[test]
    fn test_feed_type_display() {
        assert_eq!(FeedType::SpotMedian.to_string(), "Spot Median");
        assert_eq!(FeedType::TWAP.to_string(), "TWAP");
        assert_eq!(FeedType::RealizedVolatility.to_string(), "Realized Volatility");
        assert_eq!(FeedType::Options.to_string(), "Options");
        assert_eq!(FeedType::Perp.to_string(), "Perp");
    }

    #[test]
    fn test_asset_class_display() {
        assert_eq!(AssetClass::Crypto.to_string(), "Crypto");
    }

    #[test]
    fn test_feed_type_from_u16() {
        assert_eq!(FeedType::try_from(21325).unwrap(), FeedType::SpotMedian);
        assert_eq!(FeedType::try_from(21591).unwrap(), FeedType::TWAP);
        assert_eq!(FeedType::try_from(21078).unwrap(), FeedType::RealizedVolatility);
        assert_eq!(FeedType::try_from(20304).unwrap(), FeedType::Options);
        assert_eq!(FeedType::try_from(20560).unwrap(), FeedType::Perp);
        assert!(FeedType::try_from(0).is_err());
    }

    #[test]
    fn test_feed_from_str_invalid_id() {
        let feed_id = "0x12"; // Too short
        let result: anyhow::Result<Feed> = feed_id.parse();
        assert!(result.is_err());
    }

    #[test]
    fn test_feed_from_str_without_0x_prefix() {
        let feed_id = "0x01534d4254432f555344";
        let result: Feed = feed_id.parse().unwrap();
        assert_eq!(result.asset_class, AssetClass::Crypto);
        assert_eq!(result.feed_type, FeedType::SpotMedian);
        assert_eq!(result.pair_id, "BTC/USD");
    }

    #[test]
    fn test_feed_from_str_invalid_asset_class() {
        let feed_id = "0x02534d4254432f555344";
        let result: anyhow::Result<Feed> = feed_id.parse();
        assert!(result.is_err());
    }
}
