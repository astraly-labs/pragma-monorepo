use alexandria_bytes::{Bytes, BytesTrait};

use pragma_feed_types::types::{AssetClass, AssetClassId, FeedId, FeedType, Feed};
use pragma_feed_types::types::feed::{StringTryIntoFeedId, FeedIdTryIntoFeed};
#[test]
fn test_valid_feed_id_conversion() {
    let feed = Feed {
        asset_class: AssetClass::Crypto,
        feed_type: FeedType::SpotMedian,
        pair_id: 'BTC/USD',
    };
    let feed_id: FeedId = feed.into();

    let result: Option<Feed> = feed_id.clone().try_into();
    
    let feed = result.unwrap();
    assert(feed.asset_class == AssetClass::Crypto, 'Incorrect asset_class');
    assert(feed.feed_type == FeedType::SpotMedian, 'Incorrect feed_type');
    assert(feed.pair_id == 'BTC/USD', 'Incorrect pair_id');
    assert(feed_id == feed.into(), 'Incorrect feed id');
}

#[test]
fn test_valid_string_to_feed_id_conversion() {
    let expected_feed = Feed {
        asset_class: AssetClass::Crypto,
        feed_type: FeedType::SpotMedian,
        pair_id: 'BTC/USD',
    };
    let feed_as_string: ByteArray = expected_feed.clone().into();

    let feed_id: FeedId = feed_as_string.clone().into();
    let out_feed: Feed = feed_id.try_into().unwrap();

    println!("{:?}", feed_as_string);
    assert(out_feed == expected_feed, 'Incorrect feed');
}
