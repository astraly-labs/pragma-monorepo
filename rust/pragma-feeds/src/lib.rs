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
//! - Twap (21591)
//! - Realized Volatility (21078)
//! - Options (20304)
//! - Perp (20560)
use std::convert::TryFrom;
use std::str::FromStr;

use anyhow::{anyhow, bail, Context};
use serde::{Deserialize, Serialize};
use strum_macros::{Display, EnumString};

#[derive(Debug, PartialEq, Serialize, Deserialize)]
pub struct Feed {
    pub feed_id: String,
    pub asset_class: AssetClass,
    pub feed_type: FeedType,
    pub pair_id: String,
}

#[derive(Debug, PartialEq, Display, EnumString, Serialize, Deserialize, Clone, Copy)]
pub enum AssetClass {
    Crypto = 0,
}

impl TryFrom<u16> for AssetClass {
    type Error = anyhow::Error;

    fn try_from(value: u16) -> anyhow::Result<Self> {
        match value {
            0 => Ok(AssetClass::Crypto),
            _ => Err(anyhow!("Unknown asset class: {}", value)),
        }
    }
}

// TODO:
// This configuration is wrong at the moment. We should include:
// FeedType(FeedVariant).
// For now it works because we only have 0 anyway.
#[derive(Debug, PartialEq, Display, EnumString, Serialize, Deserialize, Clone, Copy)]
pub enum FeedType {
    #[strum(serialize = "Unique Spot Median")]
    UniqueSpotMedian = 0,
}

impl TryFrom<u16> for FeedType {
    type Error = anyhow::Error;

    fn try_from(value: u16) -> anyhow::Result<Self> {
        match value {
            0 => Ok(FeedType::UniqueSpotMedian),
            _ => Err(anyhow!("Unknown feed type: {}", value)),
        }
    }
}

impl FromStr for Feed {
    type Err = anyhow::Error;

    fn from_str(feed_id: &str) -> anyhow::Result<Self> {
        let stripped_id = feed_id.strip_prefix("0x").unwrap_or(feed_id);
        let mut bytes = hex::decode(stripped_id)?;

        if bytes.len() < 3 {
            bail!("Feed ID is too short");
        }

        if bytes.len() > 35 {
            bail!("Feed ID is too long");
        }

        // Pad the bytes to 35 if necessary, but at the end
        let original_len = bytes.len();
        bytes.resize(35, 0);
        bytes.rotate_right(35 - original_len);

        let asset_class = AssetClass::try_from(u16::from_be_bytes([bytes[0], bytes[1]]))?;
        let feed_type = FeedType::try_from(u16::from_be_bytes([bytes[2], bytes[3]]))?;

        let pair_id = String::from_utf8(bytes[3..].to_vec())
            .context("Invalid UTF-8 sequence for pair_id")?
            .trim_start_matches('\0')
            .to_string();

        if pair_id.is_empty() {
            bail!("Empty pair ID");
        }

        Ok(Feed { feed_id: feed_id.to_owned(), asset_class, feed_type, pair_id })
    }
}

impl Feed {
    /// Creates a new Feed from its components and generates the corresponding feed_id.
    ///
    /// # Arguments
    ///
    /// * `asset_class` - The asset class of the feed
    /// * `feed_type` - The type of feed
    /// * `pair_id` - The trading pair identifier
    ///
    /// # Returns
    ///
    /// A new `Feed` instance with the generated feed_id
    pub fn new(asset_class: AssetClass, feed_type: FeedType, pair_id: String) -> Self {
        let feed_id = Self::generate_feed_id(&asset_class, &feed_type, &pair_id);
        Feed { feed_id, asset_class, feed_type, pair_id }
    }

    /// Generates a feed_id from its components.
    ///
    /// # Arguments
    ///
    /// * `asset_class` - The asset class of the feed
    /// * `feed_type` - The type of feed
    /// * `pair_id` - The trading pair identifier
    ///
    /// # Returns
    ///
    /// A string representing the feed_id in hexadecimal format with "0x" prefix
    pub fn generate_feed_id(asset_class: &AssetClass, feed_type: &FeedType, pair_id: &str) -> String {
        // Keep it simple - just concatenate the bytes without padding to 35 bytes
        // The parsing function will handle the padding if needed

        let mut bytes = Vec::new();

        // Asset class - 1 byte (the lower byte of the u16 value)
        bytes.push(*asset_class as u8);

        // Feed type - 2 bytes (represented as "SM" for Spot Median, etc.)
        let feed_type_value = *feed_type as u16;
        bytes.extend_from_slice(&[feed_type_value as u8]);

        // Pair ID - remaining bytes
        bytes.extend_from_slice(pair_id.as_bytes());

        format!("0x{}", hex::encode(&bytes))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_feed_from_str() {
        let feed_id = "0x4254432f555344";
        let result: Feed = feed_id.parse().unwrap();

        assert_eq!(result.asset_class, AssetClass::Crypto);
        assert_eq!(result.feed_type, FeedType::UniqueSpotMedian);
        assert_eq!(result.pair_id, "BTC/USD");
    }

    #[test]
    fn test_asset_class_display() {
        assert_eq!(AssetClass::Crypto.to_string(), "Crypto");
    }

    #[test]
    fn test_generate_feed_id() {
        let asset_class = AssetClass::Crypto;
        let feed_type = FeedType::UniqueSpotMedian;
        let pair_id = "BTC/USD";

        let feed = Feed::new(asset_class, feed_type, pair_id.to_string());

        assert_eq!(feed.pair_id, "BTC/USD");

        // Test round-trip conversion
        let parsed_feed: Feed = feed.feed_id.parse().unwrap();
        assert_eq!(parsed_feed.asset_class, AssetClass::Crypto);
        assert_eq!(parsed_feed.feed_type, FeedType::UniqueSpotMedian);
        assert_eq!(parsed_feed.pair_id, "BTC/USD");
    }
}
