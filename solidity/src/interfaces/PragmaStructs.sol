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
    uint32 timestamp;
    uint16 numberOfSources;
    uint8 decimals;
}

struct SpotMedian {
    Metadata metadata;
    uint128 price;
    uint128 volume;
}

struct TWAP {
    Metadata metadata;
    uint128 twapPrice;
    uint128 timePeriod;
    uint128 startPrice;
    uint128 endPrice;
    uint128 totalVolume;
    uint128 numberOfDataPoints;
}

struct RealizedVolatility {
    Metadata metadata;
    uint128 volatility;
    uint128 timePeriod;
    uint128 startPrice;
    uint128 endPrice;
    uint128 highPrice;
    uint128 lowPrice;
    uint128 numberOfDataPoints;
}

struct Options {
    Metadata metadata;
    uint128 strikePrice;
    uint128 impliedVolatility;
    uint128 optionPrice;
    uint128 underlyingPrice;
    int256 delta;
    int256 gamma;
    int256 vega;
    int256 theta;
    int256 rho;
    uint64 timeToExpiry;
    bool isCall;
}

struct Perp {
    Metadata metadata;
    uint128 markPrice;
    uint128 fundingRate;
    uint128 openInterest;
    uint128 volume;
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
