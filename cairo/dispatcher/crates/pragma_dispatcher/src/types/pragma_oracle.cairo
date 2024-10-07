use pragma_lib::types::{AggregationMode as TrueAggregationMode};

pub type Decimals = u32;
pub type Price = u128;
pub type SummaryStatsComputation = (Price, Decimals);

#[derive(Drop, Copy, Serde, Hash, starknet::Store)]
pub enum SimpleDataType {
    Spot,
    Perp,
}

#[derive(Drop, Copy, Serde, Hash, starknet::Store)]
pub enum AggregationMode {
    Median,
    Mean,
}

impl AggregationModeIntoTrueAggregationMode of Into<AggregationMode, TrueAggregationMode> {
    fn into(self: AggregationMode) -> TrueAggregationMode {
        match self {
            AggregationMode::Median => TrueAggregationMode::Median,
            AggregationMode::Mean => TrueAggregationMode::Mean,
        }
    }
}


#[derive(Drop, Copy, Serde, Hash, starknet::Store)]
pub enum Duration {
    OneDay,
    OneWeek,
}

#[generate_trait]
pub impl DurationImpl of DurationTrait {
    fn as_seconds(self: @Duration) -> u64 {
        match self {
            Duration::OneDay => 86400,
            Duration::OneWeek => 604800,
        }
    }
}
