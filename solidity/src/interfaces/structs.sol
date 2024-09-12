



struct DataFeed {
    bytes32 feedId;
    uint64 publishTime;
    uint32 numSourcesAggregated;
    int64 value;
}

enum DataFeedType {
    SpotMedian
}

struct DataSource {
    uint16 chainId;
    bytes32 emitterAddress;
}

struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
    uint8 validatorIndex;
}

struct HyMsg {
    uint8 version;
    uint64 timestamp;
    uint32 nonce;
    uint16 emitterChainId;
    bytes32 emitterAddress;
    bytes payload;
    Signature[] signatures;
    bytes32 hash;
}

struct Metadata {
    bytes32 feed_id;
    uint64 timestamp;
    uint16 number_of_sources;
    uint8 decimals;
}

struct SpotMedian {
    Metadata metadata;
    uint256 price;
    uint256 volume;
}

struct TWAP {
    Metadata metadata;
    uint256 twap_price;
    uint256 time_period;
    uint256 start_price;
    uint256 end_price;
    uint256 total_volume;
    uint256 number_of_data_points;
}

struct RealizedVolatility {
    Metadata metadata;
    uint256 volatility;
    uint256 time_period;
    uint256 start_price;
    uint256 end_price;
    uint256 high_price;
    uint256 low_price;
    uint256 number_of_data_points;
}

struct Options {
    Metadata metadata;
    uint256 strike_price;
    uint256 implied_volatility;
    uint256 time_to_expiry;
    bool is_call;
    uint256 underlying_price;
    uint256 option_price;
    int256 delta;
    int256 gamma;
    int256 vega;
    int256 theta;
    int256 rho;
}

struct Perp {
    Metadata metadata;
    uint256 mark_price;
    uint256 funding_rate;
    uint256 open_interest;
    uint256 volume;
}

struct ParsedData {
    FeedType dataType;
    SpotMedian spot;
    TWAP twap;
    RealizedVolatility rv;
    Options options;
    Perp perp;
}

enum FeedType {
    SpotMedian,
    Twap,
    RealizedVolatility,
    Options,
    Perpetuals
}
