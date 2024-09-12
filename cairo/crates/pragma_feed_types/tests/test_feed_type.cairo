use pragma_feed_types::{FeedType, FeedTypeId};

#[test]
fn test_feed_type_into_feed_type_id() {
    let feed = FeedType::RealizedVolatility;
    let id: FeedTypeId = feed.into();
    assert(id == 2, 'RealizedVolatility should be 2');
}

#[test]
fn test_feed_type_id_try_into_feed_type() {
    let id: FeedTypeId = 1;
    let result: Option<FeedType> = id.try_into();
    assert(result.is_some(), 'Should convert 1 to Some');
    assert(result.unwrap() == FeedType::Twap, 'Should be Twap');

    let invalid_id: FeedTypeId = 10;
    let result: Option<FeedType> = invalid_id.try_into();
    assert(result.is_none(), 'Should not convert 10');
}
