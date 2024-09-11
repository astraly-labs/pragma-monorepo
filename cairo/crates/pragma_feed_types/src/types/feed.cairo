use alexandria_bytes::{Bytes, BytesTrait};
use alexandria_math::BitShift;

use pragma_feed_types::types::{AssetClass, AssetClassId, FeedType, FeedTypeId};

pub type PairId = felt252;
pub type FeedId = Bytes; // Alexandria bytes

#[derive(Debug, Clone, Drop, PartialEq, Serde)]
pub struct Feed {
    pub asset_class: AssetClass,
    pub feed_type: FeedType,
    pub pair_id: PairId,
}

pub impl FeedIdTryIntoFeed of TryInto<FeedId, Feed> {
    fn try_into(self: Bytes) -> Option<Feed> {
        let (offset, asset_class_id) = self.read_u16(0);
        let asset_class = asset_class_id.try_into()?;

        let (offset, feed_type_id) = self.read_u16(offset);
        let feed_type = feed_type_id.try_into()?;

        let (_, pair_id) = self.read_felt252(offset);

        Option::Some(Feed { asset_class, feed_type, pair_id, })
    }
}

pub impl FeedIntoFeedId of Into<Feed, FeedId> {
    fn into(self: Feed) -> FeedId {
        let mut feed_id = BytesTrait::new_empty();
        feed_id.append_u16(self.asset_class.into());
        feed_id.append_u16(self.feed_type.into());
        feed_id.append_felt252(self.pair_id);
        feed_id
    }
}

pub impl StringTryIntoFeedId of Into<ByteArray, FeedId> {
    fn into(self: ByteArray) -> FeedId {
        let mut feed_id = BytesTrait::new_empty();

        let mut idx = 0;
        loop {
            if idx >= self.len() {
                break;
            }
            feed_id.append_u8(self.at(idx).unwrap());
            idx += 1;
        };

        feed_id
    }
}

pub const FELT252_MASK: u256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

fn up_bytes(input: u256) -> u256 {
    BitShift::shr(input, 248) & 0xFF
}

/// Retrieve the 31 low byte of a given u256 input
fn down_bytes(input: u256) -> u256 {
    input & FELT252_MASK
}

pub impl FeedIntoString of Into<Feed, ByteArray> {
    fn into(self: Feed) -> ByteArray {
        let mut new_string: ByteArray = Default::default();

        let asset_class_id: AssetClassId = self.asset_class.into();
        new_string.append_word(asset_class_id.into(), 2);

        let feed_type_id: FeedTypeId = self.feed_type.into();
        new_string.append_word(feed_type_id.into(), 2);

        let ba1 = up_bytes(self.pair_id.into());
        new_string.append_word(ba1.try_into().unwrap(), 1);
        let ba2 = down_bytes(self.pair_id.into());
        new_string.append_word(ba2.try_into().unwrap(), 31);

        new_string
    }
}
