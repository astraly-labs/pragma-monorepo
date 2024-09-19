#[derive(Debug, Drop, Copy, Serde, PartialEq, Hash, starknet::Store)]
pub enum FeedType {
    Unique: UniqueVariant,
    Twap: TwapVariant,
    RealizedVolatility: RealizedVolatilityVariant,
}

#[derive(Debug, Drop, Copy, Serde, PartialEq, Hash, starknet::Store)]
pub enum UniqueVariant {
    SpotMedian,
    PerpMedian,
    SpotMean,
}

#[derive(Debug, Drop, Copy, Serde, PartialEq, Hash, starknet::Store)]
pub enum TwapVariant {
    SpotMedianOneDay,
}

#[derive(Debug, Drop, Copy, Serde, PartialEq, Hash, starknet::Store)]
pub enum RealizedVolatilityVariant {
    OneWeek,
}

/// A feed type ID is a 2 bytes identifier:
/// * the first byte corresponds to the Feed Type,
/// * the second byte corresponds to the Feed Type Variant.
/// See the enums above for more info.
pub type FeedTypeId = u16;

/// Constants for FeedType bit manipulation.
const FEED_TYPE_MAIN_SHIFT: u16 = 0x100;
const FEED_TYPE_MAIN_MASK: u16 = 0xFF00;
const FEED_TYPE_VARIANT_MASK: u16 = 0x00FF;

#[derive(Debug, Drop, Copy, PartialEq)]
pub enum FeedTypeError {
    IdConversion: felt252,
}

impl FeedTypeErrorIntoFelt252 of Into<FeedTypeError, felt252> {
    fn into(self: FeedTypeError) -> felt252 {
        match self {
            FeedTypeError::IdConversion(msg) => msg,
        }
    }
}

#[generate_trait]
pub impl FeedTypeTraitImpl of FeedTypeTrait {
    /// Try to construct a FeedType from the provided FeedTypeId.
    fn from_id(id: FeedTypeId) -> Result<FeedType, FeedTypeError> {
        let main_type = (id & FEED_TYPE_MAIN_MASK) / FEED_TYPE_MAIN_SHIFT;
        let variant = id & FEED_TYPE_VARIANT_MASK;

        match main_type {
            0 => match variant {
                0 => Result::Ok(FeedType::Unique(UniqueVariant::SpotMedian)),
                1 => Result::Ok(FeedType::Unique(UniqueVariant::PerpMedian)),
                2 => Result::Ok(FeedType::Unique(UniqueVariant::SpotMean)),
                _ => Result::Err(FeedTypeError::IdConversion('Unknown feed type variant')),
            },
            1 => match variant {
                0 => Result::Ok(FeedType::Twap(TwapVariant::SpotMedianOneDay)),
                _ => Result::Err(FeedTypeError::IdConversion('Unknown feed type variant')),
            },
            2 => match variant {
                0 => Result::Ok(FeedType::RealizedVolatility(RealizedVolatilityVariant::OneWeek)),
                _ => Result::Err(FeedTypeError::IdConversion('Unknown feed type variant')),
            },
            _ => Result::Err(FeedTypeError::IdConversion('Unknown feed type')),
        }
    }

    /// Returns the id of the FeedType.
    fn id(self: @FeedType) -> FeedTypeId {
        match self {
            FeedType::Unique(variant) => {
                let unique_id = 0;
                let variant_id = match variant {
                    UniqueVariant::SpotMedian => 0,
                    UniqueVariant::PerpMedian => 1,
                    UniqueVariant::SpotMean => 2,
                };
                (unique_id * FEED_TYPE_MAIN_SHIFT) + variant_id
            },
            FeedType::Twap(variant) => {
                let twap_id = 1;
                let variant_id = match variant {
                    TwapVariant::SpotMedianOneDay => 0,
                };
                (twap_id * FEED_TYPE_MAIN_SHIFT) + variant_id
            },
            FeedType::RealizedVolatility(variant) => {
                let realized_volatility_id = 2;
                let variant_id = match variant {
                    RealizedVolatilityVariant::OneWeek => 0,
                };
                (realized_volatility_id * FEED_TYPE_MAIN_SHIFT) + variant_id
            },
        }
    }

    /// Checks if the feed type is Unique.
    fn is_unique(self: @FeedType) -> bool {
        match self {
            FeedType::Unique(_) => true,
            _ => false
        }
    }
}
