use pragma_feed_types::{AssetClass, AssetClassId, FeedType, FeedTypeId};
use pragma_maths::felt252::{FeltBitAnd, FeltDiv, FeltOrd};

// Constants used for felt manipulations when decoding the FeedId.
const ASSET_CLASS_SHIFT: felt252 = 0x100000000000000000000000000000000; // 2^128
const FEED_TYPE_SHIFT: felt252 = 0x100000000000000; // 2^64
const FEED_TYPE_MASK: felt252 = 0xFFFFFFFFFFFFFFFF; // 2^64 - 1
const MAX_PAIR_ID: felt252 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // 2^224 - 1 (28 bytes)

// Type aliases for identifiers.
pub type PairId = felt252;
pub type FeedId = felt252;

#[derive(Debug, Clone, Drop, PartialEq, Serde)]
pub struct Feed {
    pub asset_class: AssetClass,
    pub feed_type: FeedType,
    pub pair_id: PairId,
}

#[derive(Drop, Copy, PartialEq)]
pub enum FeedError {
    Conversion: felt252,
}

impl FeedErrorIntoFelt of Into<FeedError, felt252> {
    fn into(self: FeedError) -> felt252 {
        match self {
            FeedError::Conversion(msg) => msg,
        }
    }
}

#[generate_trait]
pub impl FeedTraitImpl of FeedTrait {
    /// Try to construct a Feed from the provided FeedId.
    fn from_id(id: FeedId) -> Result<Feed, FeedError> {
        // Extract asset_class (first 2 bytes)
        let asset_class_felt = id / ASSET_CLASS_SHIFT;
        let asset_class_option: Option<AssetClass> = asset_class_felt.try_into();
        if asset_class_option.is_none() {
            return Result::Err(FeedError::Conversion('Invalid asset class encoding'));
        }

        // Extract feed_type (next 2 bytes)
        let feed_type_felt = (id / FEED_TYPE_SHIFT) & FEED_TYPE_MASK;
        let feed_type_option: Option<FeedType> = feed_type_felt.try_into();
        if feed_type_option.is_none() {
            return Result::Err(FeedError::Conversion('Invalid feed type encoding'));
        }

        // Extract pair_id (remaining bytes, maximum 28)
        let pair_id = id
            - (asset_class_felt * ASSET_CLASS_SHIFT)
            - (feed_type_felt * FEED_TYPE_SHIFT);

        // Check if pair_id exceeds 28 bytes
        if pair_id > MAX_PAIR_ID {
            return Result::Err(FeedError::Conversion('Pair id greater than 28 bytes'));
        }

        Result::Ok(
            Feed {
                asset_class: asset_class_option.unwrap(), // safe unwrap
                feed_type: feed_type_option.unwrap(), // safe unwrap
                pair_id
            }
        )
    }

    /// Returns the id of the Feed.
    fn id(self: @Feed) -> FeedId {
        let asset_class_id: AssetClassId = (*self.asset_class).into();
        let asset_class_felt: felt252 = asset_class_id.into();

        let feed_type_id: FeedTypeId = (*self.feed_type).into();
        let feed_type_felt: felt252 = feed_type_id.into();

        // Shift left by 128 bits
        let shifted_asset_class = asset_class_felt * ASSET_CLASS_SHIFT;
        // Shift left by 64 bits
        let shifted_feed_type = feed_type_felt * FEED_TYPE_SHIFT;

        // Combine all fields
        shifted_asset_class + shifted_feed_type + *self.pair_id
    }
}
