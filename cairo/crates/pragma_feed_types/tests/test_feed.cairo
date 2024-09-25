use pragma_feed_types::asset_class::{AssetClass};
use pragma_feed_types::feed::{
    ASSET_CLASS_SHIFT, FEED_TYPE_SHIFT, FeedId, Feed, FeedTrait, MAX_PAIR_ID
};
use pragma_feed_types::feed_type::{
    FeedType, FeedTypeTrait, UniqueVariant, RealizedVolatilityVariant
};
use pragma_maths::felt252::{felt252_to_u256, FeltBitAnd, FeltDiv, FeltOrd};

#[test]
fn test_valid_feed_id_conversion() {
    let expected_feed = Feed {
        asset_class: AssetClass::Crypto,
        feed_type: FeedType::RealizedVolatility(RealizedVolatilityVariant::OneWeek),
        pair_id: 'BTC/USD',
    };
    let feed_id: FeedId = expected_feed.id().unwrap();

    let out_feed: Feed = FeedTrait::from_id(feed_id).unwrap();
    assert(out_feed.asset_class == expected_feed.asset_class, 'Incorrect asset_class');
    assert(out_feed.feed_type == expected_feed.feed_type, 'Incorrect feed_type');
    assert(out_feed.pair_id == expected_feed.pair_id, 'Incorrect pair_id');
    assert(out_feed.id().unwrap() == feed_id, 'Incorrect feed id');

    let expected_feed = Feed {
        asset_class: AssetClass::Crypto,
        feed_type: FeedType::RealizedVolatility(RealizedVolatilityVariant::OneWeek),
        pair_id: 'EKUBO/USD',
    };
    let feed_id: FeedId = expected_feed.id().unwrap();
    let out_feed: Feed = FeedTrait::from_id(feed_id).unwrap();
    assert(out_feed.asset_class == expected_feed.asset_class, 'Incorrect asset_class');
    assert(out_feed.feed_type == expected_feed.feed_type, 'Incorrect feed_type');
    assert(out_feed.pair_id == expected_feed.pair_id, 'Incorrect pair_id');
    assert(out_feed.id().unwrap() == feed_id, 'Incorrect feed id');

    let expected_feed = Feed {
        asset_class: AssetClass::Crypto,
        feed_type: FeedType::RealizedVolatility(RealizedVolatilityVariant::OneWeek),
        pair_id: MAX_PAIR_ID - 1,
    };
    let feed_id: FeedId = expected_feed.id().unwrap();
    let out_feed: Feed = FeedTrait::from_id(feed_id).unwrap();
    assert(out_feed.asset_class == expected_feed.asset_class, 'Incorrect asset_class');
    assert(out_feed.feed_type == expected_feed.feed_type, 'Incorrect feed_type');
    assert(out_feed.pair_id == expected_feed.pair_id, 'Incorrect pair_id');
    assert(out_feed.id().unwrap() == feed_id, 'Incorrect feed id');
}

#[test]
fn test_pair_id_exceeds_max() {
    let invalid_feed = Feed {
        asset_class: AssetClass::Crypto,
        feed_type: FeedType::Unique(UniqueVariant::SpotMedian),
        pair_id: MAX_PAIR_ID + 1
    };
    let result = invalid_feed.id();
    assert(result.is_err(), 'should have errored');
}

#[test]
fn test_feed_id_components() {
    let asset_class = AssetClass::Crypto;
    let feed_type = FeedType::RealizedVolatility(RealizedVolatilityVariant::OneWeek);
    let pair_id = 'EUR/USD';

    let feed = Feed { asset_class, feed_type, pair_id };
    let feed_id = feed.id().unwrap();

    let asset_class_component = feed_id / ASSET_CLASS_SHIFT;
    let feed_type_component = (feed_id / FEED_TYPE_SHIFT) & 0xFFFFFFFFFFFFFFFF;
    let pair_id_component: felt252 = (felt252_to_u256(feed_id) % felt252_to_u256(FEED_TYPE_SHIFT))
        .try_into()
        .unwrap();

    assert(asset_class_component == asset_class.into(), 'Wrong asset class component');
    assert(
        feed_type_component == FeedTypeTrait::id(@feed_type).into(), 'Wrong feed type component'
    );
    assert(pair_id_component == pair_id, 'Wrong pair id component');
}
