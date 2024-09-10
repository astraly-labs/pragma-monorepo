use std::convert::TryFrom;
use std::str::FromStr;

use anyhow::{anyhow, Context};
use hex;
use strum_macros::{Display, EnumString};

/// TODO: At the moment, the asset class isn't present in the feed_id.
/// We consider everything to be Crypto.
#[derive(Debug, PartialEq, Display, EnumString)]
pub enum AssetClass {
    Crypto,
}

#[derive(Debug, PartialEq)]
pub struct Feed {
    pub asset_class: AssetClass,
    pub feed_type: FeedType,
    pub pair_id: String,
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

    fn from_str(feed_id: &str) -> Result<Self, Self::Err> {
        let feed_id = feed_id.strip_prefix("0x").unwrap_or(feed_id);
        let bytes = hex::decode(feed_id)?;

        if bytes.len() < 45 {
            // * 2 bytes for type
            // * 11 bytes for metadata
            // * 32 bytes for pair_id
            return Err(anyhow!("Feed ID is too short"));
        }

        let feed_type = FeedType::try_from(u16::from_be_bytes([bytes[0], bytes[1]]))?;

        // Skip metadata (11 bytes) and parse pair_id (32 bytes)
        let pair_id_bytes = &bytes[13..45];
        let pair_id = String::from_utf8(pair_id_bytes.to_vec())
            .context("Invalid UTF-8 sequence for pair_id")?
            .trim_start_matches('\0')
            .trim_end_matches('\0')
            .to_string();

        if pair_id.is_empty() {
            return Err(anyhow!("Empty pair ID"));
        }

        Ok(Feed { asset_class: AssetClass::Crypto, feed_type, pair_id })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_feed_from_str() {
        let feed_id =
            "0x534D000000000000000000000000004254432F55534400000000000000000000000000000000000000000000000000";
        let result: Feed = feed_id.parse().unwrap();

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
        let feed_id = "0x1234"; // Too short
        let result: Result<Feed, _> = feed_id.parse();
        assert!(result.is_err());
    }

    #[test]
    fn test_feed_from_str_without_0x_prefix() {
        let feed_id = "534D000000000000000000000000004254432F55534400000000000000000000000000000000000000000000000000";
        let result: Feed = feed_id.parse().unwrap();
        assert_eq!(result.feed_type, FeedType::SpotMedian);
        assert_eq!(result.pair_id, "BTC/USD");
    }
}
