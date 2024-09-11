use alexandria_bytes::{Bytes, BytesTrait};
use pragma_feed_types::traits::IntoBytes;

use pragma_feed_types::types::{AssetClass, AssetClassId};

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
}
