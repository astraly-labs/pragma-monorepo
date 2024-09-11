use alexandria_bytes::{Bytes, BytesTrait};

use pragma_feed_types::traits::IntoBytes;

#[derive(Debug, Drop, Clone, Serde, PartialEq, Hash)]
pub enum AssetClass {
    Crypto,
}

pub type AssetClassId = u16;

impl AssetClassIntoAssetClassId of Into<AssetClass, AssetClassId> {
    fn into(self: AssetClass) -> AssetClassId {
        match self {
            AssetClass::Crypto => 1,
        }
    }
}

impl AssetClassIdTryIntoAssetClass of TryInto<AssetClassId, AssetClass> {
    fn try_into(self: u16) -> Option<AssetClass> {
        match self {
            0 => Option::None(()), // must start from 0 else syntax error
            1 => Option::Some(AssetClass::Crypto),
            _ => Option::None(())
        }
    }
}

impl FeltTryIntoAssetClass of TryInto<felt252, AssetClass> {
    fn try_into(self: felt252) -> Option<AssetClass> {
        let value: AssetClassId = self.try_into()?;
        value.try_into()
    }
}

impl AssetClassIntoBytes of IntoBytes<AssetClass> {
    fn into_bytes(self: AssetClass) -> Bytes {
        let asset_class_id: AssetClassId = self.into();
        let mut bytes = BytesTrait::new_empty();
        bytes.append_u16(asset_class_id);
        bytes
    }
}
