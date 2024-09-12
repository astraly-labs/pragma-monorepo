#[derive(Debug, Drop, Copy, Serde, PartialEq, Hash)]
pub enum FeedType {
    SpotMedian,
    Twap,
    RealizedVolatility,
    Option,
    Perp,
}

pub type FeedTypeId = u16;

impl FeedTypeIntoFeedTypeId of Into<FeedType, FeedTypeId> {
    fn into(self: FeedType) -> FeedTypeId {
        match self {
            FeedType::SpotMedian => 0,
            FeedType::Twap => 1,
            FeedType::RealizedVolatility => 2,
            FeedType::Option => 3,
            FeedType::Perp => 4,
        }
    }
}

impl FeedTypeIntoString of Into<FeedType, ByteArray> {
    fn into(self: FeedType) -> ByteArray {
        match self {
            FeedType::SpotMedian => "Spot Median",
            FeedType::Twap => "Twap",
            FeedType::RealizedVolatility => "Realized Volatility",
            FeedType::Option => "Option",
            FeedType::Perp => "Perp",
        }
    }
}

impl FeedTypeIdTryIntoFeedType of TryInto<FeedTypeId, FeedType> {
    fn try_into(self: u16) -> Option<FeedType> {
        match self {
            0 => Option::Some(FeedType::SpotMedian),
            1 => Option::Some(FeedType::Twap),
            2 => Option::Some(FeedType::RealizedVolatility),
            3 => Option::Some(FeedType::Option),
            4 => Option::Some(FeedType::Perp),
            _ => Option::None(())
        }
    }
}

impl FeltTryIntoFeedType of TryInto<felt252, FeedType> {
    fn try_into(self: felt252) -> Option<FeedType> {
        let value: FeedTypeId = self.try_into()?;
        value.try_into()
    }
}
