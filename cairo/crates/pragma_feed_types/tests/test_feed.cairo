use pragma_feed_types::asset_class::{AssetClass};
use pragma_feed_types::feed::{
    ASSET_CLASS_SHIFT, FEED_TYPE_SHIFT, FeedId, Feed, FeedTrait, MAX_PAIR_ID
};
use pragma_feed_types::feed_type::{
    FeedType, FeedTypeTrait, UniqueVariant, TwapVariant, RealizedVolatilityVariant
};
use pragma_maths::felt252::{FeltBitAnd, FeltDiv, FeltOrd};

fn create_random_feed(asset_class: AssetClass, feed_type: FeedType, pair_id: felt252) -> Feed {
    Feed { asset_class, feed_type, pair_id }
}

// Utility for conversion
fn felt252_to_u256(nb: felt252) -> u256 {
    Into::<felt252, u256>::into(nb)
}

#[test]
fn test_valid_feed_id_conversion() {
    let expected_feed = Feed {
        asset_class: AssetClass::Crypto,
        feed_type: FeedType::RealizedVolatility(RealizedVolatilityVariant::OneWeek),
        pair_id: 'BTC/USD',
    };
    let feed_id: FeedId = expected_feed.id();

    let out_feed: Feed = FeedTrait::from_id(feed_id).unwrap();
    assert(out_feed.asset_class == expected_feed.asset_class, 'Incorrect asset_class');
    assert(out_feed.feed_type == expected_feed.feed_type, 'Incorrect feed_type');
    assert(out_feed.pair_id == expected_feed.pair_id, 'Incorrect pair_id');
    assert(out_feed.id() == feed_id, 'Incorrect feed id');
}

#[test]
fn test_no_collision_random_feeds(
    pair_id1: felt252, feed_type_1: u8, pair_id2: felt252, feed_type_2: u8,
) {
    let feed_type_1 = match feed_type_1 % 3 {
        0 => FeedType::Unique(UniqueVariant::SpotMedian),
        1 => FeedType::Twap(TwapVariant::OneDay),
        2 => FeedType::RealizedVolatility(RealizedVolatilityVariant::OneWeek),
        _ => panic_with_felt252('Unexpected feed type')
    };
    let feed_type_2 = match feed_type_2 % 3 {
        0 => FeedType::Unique(UniqueVariant::SpotMedian),
        1 => FeedType::Twap(TwapVariant::OneDay),
        2 => FeedType::RealizedVolatility(RealizedVolatilityVariant::OneWeek),
        _ => panic_with_felt252('Unexpected feed type')
    };

    // Ugly lines to avoid pair id > 28 bytes
    let pair_id1: felt252 = (felt252_to_u256(pair_id1) % felt252_to_u256(MAX_PAIR_ID))
        .try_into()
        .unwrap();
    let pair_id2: felt252 = (felt252_to_u256(pair_id2) % felt252_to_u256(MAX_PAIR_ID))
        .try_into()
        .unwrap();

    let feed1 = create_random_feed(AssetClass::Crypto, feed_type_1, pair_id1);
    let feed2 = create_random_feed(AssetClass::Crypto, feed_type_2, pair_id2);

    let id1: FeedId = feed1.id();
    let id2: FeedId = feed2.id();

    if feed1 != feed2 {
        assert(id1 != id2, 'IDs should be different');
    } else {
        assert(id1 == id2, 'IDs should be same');
    }
}

#[test]
fn test_pair_id_exceeds_max() {
    let invalid_feed = Feed {
        asset_class: AssetClass::Crypto,
        feed_type: FeedType::Unique(UniqueVariant::SpotMedian),
        pair_id: MAX_PAIR_ID + 1
    };
    let feed_id = invalid_feed.id();

    let result = FeedTrait::from_id(feed_id);
    assert(result.is_err(), 'should have errored');
}

#[test]
fn test_feed_id_components() {
    let asset_class = AssetClass::Crypto;
    let feed_type = FeedType::RealizedVolatility(RealizedVolatilityVariant::OneWeek);
    let pair_id = 'EUR/USD';

    let feed = Feed { asset_class, feed_type, pair_id };
    let feed_id = feed.id();

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
