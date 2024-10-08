#[derive(Debug, Drop, Copy, Serde, PartialEq, Hash, starknet::Store)]
pub enum AssetClass {
    Crypto,
}

pub type AssetClassId = u16;

impl AssetClassIntoAssetClassId of Into<AssetClass, AssetClassId> {
    fn into(self: AssetClass) -> AssetClassId {
        match self {
            AssetClass::Crypto => 0,
        }
    }
}

impl AssetClassIntoAssetfelt252 of Into<AssetClass, felt252> {
    fn into(self: AssetClass) -> felt252 {
        match self {
            AssetClass::Crypto => 0,
        }
    }
}

impl AssetClassIntoString of Into<AssetClass, ByteArray> {
    fn into(self: AssetClass) -> ByteArray {
        match self {
            AssetClass::Crypto => "Crypto",
        }
    }
}

impl AssetClassIdTryIntoAssetClass of TryInto<AssetClassId, AssetClass> {
    fn try_into(self: u16) -> Option<AssetClass> {
        match self {
            0 => Option::Some(AssetClass::Crypto),
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
