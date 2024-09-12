// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

struct DataFeed {
    bytes32 feedId;
    uint64 publishTime;
    uint32 numSourcesAggregated;
    uint256 value;
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
    bytes32 feedId;
    uint64 timestamp;
    uint16 numberOfSources;
    uint8 decimals;
}

struct SpotMedian {
    Metadata metadata;
    uint256 price;
    uint256 volume;
}

struct TWAP {
    Metadata metadata;
    uint256 twapPrice;
    uint256 timePeriod;
    uint256 startPrice;
    uint256 endPrice;
    uint256 totalVolume;
    uint256 numberOfDataPoints;
}

struct RealizedVolatility {
    Metadata metadata;
    uint256 volatility;
    uint256 timePeriod;
    uint256 startPrice;
    uint256 endPrice;
    uint256 high_price;
    uint256 low_price;
    uint256 numberOfDataPoints;
}

struct Options {
    Metadata metadata;
    uint256 strikePrice;
    uint256 impliedVolatility;
    uint256 timeToExpiry;
    bool isCall;
    uint256 underlyingPrice;
    uint256 optionPrice;
    int256 delta;
    int256 gamma;
    int256 vega;
    int256 theta;
    int256 rho;
}

struct Perp {
    Metadata metadata;
    uint256 markPrice;
    uint256 fundingRate;
    uint256 openInterest;
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
