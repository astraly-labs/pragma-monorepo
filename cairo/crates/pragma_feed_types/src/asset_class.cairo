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
