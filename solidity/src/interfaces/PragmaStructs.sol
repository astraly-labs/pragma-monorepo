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
    uint256 highPrice;
    uint256 lowPrice;
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

library StructsInitializers {
    function initializeParsedData() public pure returns (ParsedData memory) {
        ParsedData memory parsed = ParsedData({
            dataType: FeedType.SpotMedian,
            spot: initializeSpotMedian(),
            twap: initializeTwap(),
            rv: initializeRV(),
            options: initializeOptions(),
            perp: initializePerpetuals()
        });

        return parsed;
    }

    function initializeMetadata() public pure returns (Metadata memory) {
        Metadata memory metadata = Metadata({feedId: 0, timestamp: 0, numberOfSources: 0, decimals: 0});
        return metadata;
    }

    function initializeSpotMedian() public pure returns (SpotMedian memory) {
        Metadata memory metadata = initializeMetadata();
        SpotMedian memory spotMedian = SpotMedian({metadata: metadata, price: 0, volume: 0});
        return spotMedian;
    }

    function initializeTwap() public pure returns (TWAP memory) {
        Metadata memory metadata = initializeMetadata();
        TWAP memory twap = TWAP({
            metadata: metadata,
            twapPrice: 0,
            timePeriod: 0,
            startPrice: 0,
            endPrice: 0,
            totalVolume: 0,
            numberOfDataPoints: 0
        });
        return twap;
    }

    function initializeRV() public pure returns (RealizedVolatility memory) {
        Metadata memory metadata = initializeMetadata();
        RealizedVolatility memory rv = RealizedVolatility({
            metadata: metadata,
            volatility: 0,
            timePeriod: 0,
            startPrice: 0,
            endPrice: 0,
            highPrice: 0,
            lowPrice: 0,
            numberOfDataPoints: 0
        });
        return rv;
    }

    function initializeOptions() public pure returns (Options memory) {
        Metadata memory metadata = initializeMetadata();
        Options memory options = Options({
            metadata: metadata,
            strikePrice: 0,
            impliedVolatility: 0,
            timeToExpiry: 0,
            isCall: false,
            underlyingPrice: 0,
            optionPrice: 0,
            delta: 0,
            gamma: 0,
            vega: 0,
            theta: 0,
            rho: 0
        });
        return options;
    }

    function initializePerpetuals() public pure returns (Perp memory) {
        Metadata memory metadata = Metadata({feedId: 0, timestamp: 0, numberOfSources: 0, decimals: 0});
        Perp memory perpetuals = Perp({metadata: metadata, markPrice: 0, fundingRate: 0, openInterest: 0, volume: 0});
        return perpetuals;
    }
}
