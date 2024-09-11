use pragma_feed_types::{FeedType, FeedTypeId};

#[test]
fn test_feed_type_into_feed_type_id() {
    let feed = FeedType::RealizedVolatility;
    let id: FeedTypeId = feed.into();
    assert(id == 3, 'Crypto should convert to 3');
}

#[test]
fn test_feed_type_id_try_into_feed_type() {
    let id: FeedTypeId = 2;
    let result: Option<FeedType> = id.try_into();
    assert(result.is_some(), 'Should convert 1 to Some');
    assert(result.unwrap() == FeedType::Twap, 'Should be Crypto');

    let invalid_id: FeedTypeId = 0;
    let result: Option<FeedType> = invalid_id.try_into();
    assert(result.is_none(), 'Should not convert 0');
}
