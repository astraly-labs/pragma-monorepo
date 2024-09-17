use pragma_feed_types::feed_type::{
    FeedType, FeedTypeId, FeedTypeTrait, FeedTypeError, UniqueVariant
};

#[test]
fn test_feed_type_from_id_valid() {
    let id: FeedTypeId = 0x0001; // Unique::PerpMedian
    let result = FeedTypeTrait::from_id(id);
    assert(result.is_ok(), 'Should be Ok');
    assert(result.unwrap() == FeedType::Unique(UniqueVariant::PerpMedian), 'Incorrect FeedType');
}

#[test]
fn test_feed_type_from_id_invalid_main_type() {
    let id: FeedTypeId = 0x3000; // Invalid main type
    let result = FeedTypeTrait::from_id(id);
    assert(result.is_err(), 'Should be Err');

    let expected_err = FeedTypeError::IdConversion('Unknown feed type');
    assert(result.unwrap_err() == expected_err, 'Incorrect error');
}

#[test]
fn test_feed_type_from_id_invalid_variant() {
    let id: FeedTypeId = 0x0003; // Invalid Unique variant
    let result = FeedTypeTrait::from_id(id);
    assert(result.is_err(), 'Should be Err');
    let expected_err = FeedTypeError::IdConversion('Unknown feed type variant');
    assert(result.unwrap_err() == expected_err, 'Incorrect error');
}
