// Source:
// https://github.com/astraly-labs/pragma-oracle/blob/eeb381b787889221d1ed4dbef524bdd43e46ab47/src/entry/structs.cairo
// TODO: Remove those once we can import them directly

#[derive(Serde, Drop, Copy)]
pub struct PragmaPricesResponse {
    pub price: u128,
    pub decimals: u32,
    pub last_updated_timestamp: u64,
    pub num_sources_aggregated: u32,
    pub expiration_timestamp: Option<u64>,
}

#[derive(Serde, Drop, Copy, starknet::Store)]
pub enum AggregationMode {
    Median,
    Mean,
    Error,
}

#[derive(Drop, Copy, Serde)]
pub enum DataType {
    SpotEntry: felt252,
    FutureEntry: (felt252, u64),
    GenericEntry: felt252,
}

pub type Price = u128;
pub type Decimals = u32;
pub type SummaryStatsComputation = (Price, Decimals);
