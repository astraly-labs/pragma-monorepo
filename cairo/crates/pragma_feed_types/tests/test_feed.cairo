use alexandria_bytes::{Bytes, BytesTrait};
use pragma_feed_types::types::feed::FeedIdTryIntoFeed;

use pragma_feed_types::types::{AssetClass, AssetClassId, FeedId, FeedType, Feed};

fn create_random_feed(asset_class: AssetClass, feed_type: FeedType, pair_id: felt252) -> Feed {
    Feed { asset_class, feed_type, pair_id }
}

#[test]
fn test_valid_feed_id_conversion() {
    let expected_feed = Feed {
        asset_class: AssetClass::Crypto, feed_type: FeedType::SpotMedian, pair_id: 'BTC/USD',
    };
    let feed_id: FeedId = expected_feed.clone().into();

    let out_feed: Feed = feed_id.clone().try_into().unwrap();

    assert(out_feed.asset_class == expected_feed.asset_class, 'Incorrect asset_class');
    assert(out_feed.feed_type == expected_feed.feed_type, 'Incorrect feed_type');
    assert(out_feed.pair_id == expected_feed.pair_id, 'Incorrect pair_id');
    assert(out_feed == expected_feed.into(), 'Incorrect feed id');
}

#[test]
fn test_no_collision_same_asset_class_different_feed_type() {
    let feed1 = create_random_feed(AssetClass::Crypto, FeedType::SpotMedian, 'BTC/USD');
    let feed2 = create_random_feed(AssetClass::Crypto, FeedType::Twap, 'BTC/USD');

    let id1: FeedId = feed1.into();
    let id2: FeedId = feed2.into();

    assert(id1 != id2, 'IDs should be different');
}

#[test]
fn test_no_collision_different_asset_class_same_feed_type() {
    let feed1 = create_random_feed(AssetClass::Crypto, FeedType::SpotMedian, 'BTC/USD');
    let feed2 = create_random_feed(AssetClass::Crypto, FeedType::SpotMedian, 'EUR/USD');

    let id1: FeedId = feed1.into();
    let id2: FeedId = feed2.into();

    assert(id1 != id2, 'IDs should be different');
}

#[test]
fn test_no_collision_different_pair_id() {
    let feed1 = create_random_feed(AssetClass::Crypto, FeedType::SpotMedian, 'BTC/USD');
    let feed2 = create_random_feed(AssetClass::Crypto, FeedType::SpotMedian, 'ETH/USD');

    let id1: FeedId = feed1.into();
    let id2: FeedId = feed2.into();

    assert(id1 != id2, 'IDs should be different');
}

#[test]
fn test_no_collision_random_feeds(pair_id1: felt252, pair_id2: felt252) {
    let feed1 = create_random_feed(AssetClass::Crypto, FeedType::SpotMedian, pair_id1);
    let feed2 = create_random_feed(AssetClass::Crypto, FeedType::SpotMedian, pair_id2);

    let id1: FeedId = feed1.clone().into();
    let id2: FeedId = feed2.clone().into();

    if feed1 != feed2 {
        assert(id1 != id2, 'IDs should be different');
    } else {
        assert(id1 == id2, 'IDs should be same');
    }
}
