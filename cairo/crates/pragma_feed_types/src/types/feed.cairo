use core::traits::BitAnd;
use pragma_feed_types::types::{AssetClass, AssetClassId, FeedType, FeedTypeId};

pub type PairId = felt252;
pub type FeedId = felt252;

#[derive(Debug, Clone, Drop, PartialEq, Serde)]
pub struct Feed {
    pub asset_class: AssetClass,
    pub feed_type: FeedType,
    pub pair_id: PairId,
}

impl FeltBitAnd of BitAnd<felt252> {
    fn bitand(lhs: felt252, rhs: felt252) -> felt252 {
        (Into::<felt252, u256>::into(lhs) & rhs.into()).try_into().unwrap()
    }
}

impl FeltDiv of Div<felt252> {
    fn div(lhs: felt252, rhs: felt252) -> felt252 {
        // Use u256 division as the felt_div is on the modular field
        let lhs256: u256 = lhs.into();
        let rhs256: u256 = rhs.into();
        (lhs256 / rhs256).try_into().unwrap()
    }
}

pub impl FeedIntoFeedId of Into<Feed, FeedId> {
    fn into(self: Feed) -> FeedId {
        let asset_class_id: AssetClassId = self.asset_class.into();
        let asset_class_felt: felt252 = asset_class_id.into();

        let feed_type_id: FeedTypeId = self.feed_type.into();
        let feed_type_felt: felt252 = feed_type_id.into();

        let shifted_asset_class = asset_class_felt
            * 0x100000000000000000000000000000000_felt252; // Shift left by 128 bits
        let shifted_feed_type = feed_type_felt * 0x100000000000000_felt252; // Shift left by 64 bits

        // Combine all fields
        shifted_asset_class + shifted_feed_type + self.pair_id
    }
}

pub impl FeedIdTryIntoFeed of TryInto<FeedId, Feed> {
    fn try_into(self: felt252) -> Option<Feed> {
        let asset_class_felt = self / 0x100000000000000000000000000000000_felt252;
        let asset_class: AssetClass = asset_class_felt.try_into().unwrap();

        // Extract feed_type (middle 64 bits)
        let feed_type_felt = (self / 0x100000000000000_felt252) & 0xFFFFFFFFFFFFFFFF_felt252;
        let feed_type: FeedType = feed_type_felt.try_into().unwrap();

        // Extract pair_id (remaining bits)
        let pair_id = self
            - (asset_class_felt * 0x100000000000000000000000000000000_felt252)
            - (feed_type_felt * 0x100000000000000_felt252);

        Option::Some(Feed { asset_class, feed_type, pair_id })
    }
}
