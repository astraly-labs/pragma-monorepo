#[derive(Debug, Drop, Clone, Serde, PartialEq, Hash)]
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
            FeedType::SpotMedian => 1,
            FeedType::Twap => 2,
            FeedType::RealizedVolatility => 3,
            FeedType::Option => 4,
            FeedType::Perp => 5,
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
            0 => Option::None(()), // must start from 0 else syntax error
            1 => Option::Some(FeedType::SpotMedian),
            2 => Option::Some(FeedType::Twap),
            3 => Option::Some(FeedType::RealizedVolatility),
            4 => Option::Some(FeedType::Option),
            5 => Option::Some(FeedType::Perp),
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
