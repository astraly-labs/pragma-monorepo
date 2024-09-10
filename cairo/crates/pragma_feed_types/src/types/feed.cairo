use alexandria_bytes::BytesTrait;

use pragma_feed_types::types::{AssetClass, FeedType};

pub type PairId = felt252;
pub type FeedId = felt252;

pub struct Feed {
    pub asset_class: AssetClass,
    pub feed_type: FeedType,
    pub pair_id: PairId,
}

impl FeedIdTryIntoFeed of TryInto<FeedId, Feed> {
    fn try_into(self: felt252) -> Option<Feed> {
        let mut bytes = BytesTrait::new_empty();
        bytes.append_felt252(self);

        let (offset, asset_class_id) = bytes.read_u16(0);
        let asset_class = asset_class_id.try_into()?;

        let (offset, feed_type_id) = bytes.read_u16(offset);
        let feed_type = feed_type_id.try_into()?;

        let (_, pair_id) = bytes.read_felt252(offset);

        Option::Some(Feed { asset_class, feed_type, pair_id, })
    }
}
