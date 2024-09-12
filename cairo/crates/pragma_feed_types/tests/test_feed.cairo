use pragma_feed_types::{AssetClass, FeedId, FeedType, Feed, FeedTrait};

fn create_random_feed(asset_class: AssetClass, feed_type: FeedType, pair_id: felt252) -> Feed {
    Feed { asset_class, feed_type, pair_id }
}

#[test]
fn test_valid_feed_id_conversion() {
    let expected_feed = Feed {
        asset_class: AssetClass::Crypto, feed_type: FeedType::SpotMedian, pair_id: 'BTC/USD',
    };
    let feed_id: FeedId = expected_feed.id();

    let out_feed: Feed = FeedTrait::from_id(feed_id).unwrap();
    assert(out_feed.asset_class == expected_feed.asset_class, 'Incorrect asset_class');
    assert(out_feed.feed_type == expected_feed.feed_type, 'Incorrect feed_type');
    assert(out_feed.pair_id == expected_feed.pair_id, 'Incorrect pair_id');
    assert(out_feed == expected_feed.into(), 'Incorrect feed id');
}

#[test]
fn test_no_collision_random_feeds(
    pair_id1: felt252, feed_type_1: u8, pair_id2: felt252, feed_type_2: u8,
) {
    let feed_type_1: felt252 = (feed_type_1 % 4 + 1).into();
    let feed_type_2: felt252 = (feed_type_2 % 4 + 1).into();
    let feed1 = create_random_feed(AssetClass::Crypto, feed_type_1.try_into().unwrap(), pair_id1);
    let feed2 = create_random_feed(AssetClass::Crypto, feed_type_2.try_into().unwrap(), pair_id2);

    let id1: FeedId = feed1.id();
    let id2: FeedId = feed2.id();

    if feed1 != feed2 {
        assert(id1 != id2, 'IDs should be different');
    } else {
        assert(id1 == id2, 'IDs should be same');
    }
}
