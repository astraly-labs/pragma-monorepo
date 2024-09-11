use alexandria_bytes::{Bytes, BytesTrait};

use pragma_feed_types::types::{AssetClass, AssetClassId};
use pragma_feed_types::traits::IntoBytes;

#[test]
fn test_asset_class_into_asset_class_id() {
    let crypto = AssetClass::Crypto;
    let id: AssetClassId = crypto.into();
    assert(id == 1, 'Crypto should convert to 1');
}

#[test]
fn test_asset_class_id_try_into_asset_class() {
    let crypto_id: AssetClassId = 1;
    let result: Option<AssetClass> = crypto_id.try_into();
    assert(result.is_some(), 'Should convert 1 to Some');
    assert(result.unwrap() == AssetClass::Crypto, 'Should be Crypto');

    let invalid_id: AssetClassId = 0;
    let result: Option<AssetClass> = invalid_id.try_into();
    assert(result.is_none(), 'Should not convert 0');

    let another_invalid_id: AssetClassId = 2;
    let result: Option<AssetClass> = another_invalid_id.try_into();
    assert(result.is_none(), 'Should not convert 2');
}

#[test]
fn test_felt_try_into_asset_class() {
    let crypto_felt: felt252 = 1.into();
    let result: Option<AssetClass> = crypto_felt.try_into();
    assert(result.is_some(), 'Should convert 1 to Some');
    assert(result.unwrap() == AssetClass::Crypto, 'Should be Crypto');

    let invalid_felt: felt252 = 0.into();
    let result: Option<AssetClass> = invalid_felt.try_into();
    assert(result.is_none(), 'Should not convert 0');

    let another_invalid_felt: felt252 = 2.into();
    let result: Option<AssetClass> = another_invalid_felt.try_into();
    assert(result.is_none(), 'Should not convert 2');
}

#[test]
fn test_asset_class_into_bytes() {
    let crypto = AssetClass::Crypto;
    let bytes: Bytes = crypto.into_bytes();

    // Check the length of the bytes
    assert(bytes.size() == 2, 'Bytes size should be 2');

    // Check the content of the bytes
    let mut expected_bytes = BytesTrait::new_empty();
    expected_bytes.append_u16(1);
    assert(bytes == expected_bytes, 'Bytes should match');
}
