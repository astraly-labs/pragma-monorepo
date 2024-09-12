use pragma_feed_types::{AssetClass, AssetClassId, FeedType, FeedTypeId};
use pragma_maths::felt252::{FeltBitAnd, FeltDiv};

pub type PairId = felt252;
pub type FeedId = felt252;

#[derive(Debug, Clone, Drop, PartialEq, Serde)]
pub struct Feed {
    pub asset_class: AssetClass,
    pub feed_type: FeedType,
    pub pair_id: PairId,
}

pub trait FeedTrait {
    /// Try to construct a Feed from the provided FeedId.
    fn from_id(id: FeedId) -> Option<Feed>;

    /// Returns the id of the Feed.
    fn id(self: @Feed) -> FeedId;
}

pub impl FeedTraitImpl of FeedTrait {
    /// Try to construct a Feed from the provided FeedId.
    fn from_id(id: FeedId) -> Option<Feed> {
        let asset_class_felt = id / 0x100000000000000000000000000000000;
        let asset_class: AssetClass = asset_class_felt.try_into().unwrap();

        // Extract feed_type (middle 64 bits)
        let feed_type_felt = (id / 0x100000000000000) & 0xFFFFFFFFFFFFFFFF;
        let feed_type: FeedType = feed_type_felt.try_into().unwrap();

        // Extract pair_id (remaining bits, maximum 28 bytes)
        let pair_id = id
            - (asset_class_felt * 0x100000000000000000000000000000000)
            - (feed_type_felt * 0x100000000000000);

        Option::Some(Feed { asset_class, feed_type, pair_id })
    }

    /// Returns the id of the Feed.
    fn id(self: @Feed) -> FeedId {
        let asset_class_id: AssetClassId = self.asset_class.clone().into();
        let asset_class_felt: felt252 = asset_class_id.into();

        let feed_type_id: FeedTypeId = self.feed_type.clone().into();
        let feed_type_felt: felt252 = feed_type_id.into();

        // Shift left by 128 bits
        let shifted_asset_class = asset_class_felt * 0x100000000000000000000000000000000;
        // Shift left by 64 bits
        let shifted_feed_type = feed_type_felt * 0x100000000000000;

        // Combine all fields
        shifted_asset_class + shifted_feed_type + *self.pair_id
    }
}
