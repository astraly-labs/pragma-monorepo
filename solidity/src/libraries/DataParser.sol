// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BytesLib.sol";


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

library DataParser {
    using BytesLib for bytes;

    function parse(bytes memory data) internal pure returns (ParsedData memory) {
        uint8 offset =2; // type feed stored after asset class
        uint16 rawDataType = data.toUint16(offset);
        FeedType dataType = FeedType(rawDataType);

        ParsedData memory parsedData;
        parsedData.dataType = dataType;
        if (dataType == FeedType.SpotMedian) {
            parsedData.spot = parseSpotData(data);
        } else if (dataType == FeedType.Twap) {
            parsedData.twap = parseTWAPData(data);
        } else if (dataType == FeedType.RealizedVolatility) {
            parsedData.rv = parseRealizedVolatilityData(data);
        } else if (dataType == FeedType.Options) {
            parsedData.options = parseOptionsData(data);
        } else if (dataType == FeedType.Perpetuals) {
            parsedData.perp = parsePerpData(data);
        } else {
            revert("Unknown data type");
        }

        return parsedData;
    }

    function parseMetadata(bytes memory data, uint256 startIndex) internal pure returns (Metadata memory, uint256) {
        Metadata memory metadata;
        uint256 index = startIndex;

        metadata.feed_id = bytes32(data.toUint256(index));
        index += 32;

        metadata.timestamp = data.toUint64(index);
        index += 8;

        metadata.number_of_sources = uint16(data.toUint16(index));
        index += 2;

        metadata.decimals = uint8(data.toUint8(index));
        index += 1;

        return (metadata, index);
    }

    function parseSpotData(bytes memory data) internal pure returns (SpotMedian memory) {
        SpotMedian memory entry;
        uint256 index = 0;

        (entry.metadata, index) = parseMetadata(data, index);

        entry.price = data.toUint256(index);
        index += 32;

        entry.volume = data.toUint256(index);

        return entry;
    }

    function parseTWAPData(bytes memory data) internal pure returns (TWAP memory) {
        TWAP memory entry;
        uint256 index = 0;

        (entry.metadata, index) = parseMetadata(data, index);

        entry.twap_price = data.toUint256(index);
        index += 32;

        entry.time_period = data.toUint256(index);
        index += 32;

        entry.start_price = data.toUint256(index);
        index += 32;

        entry.end_price = data.toUint256(index);
        index += 32;

        entry.total_volume = data.toUint256(index);
        index += 32;

        entry.number_of_data_points = data.toUint256(index);

        return entry;
    }

    function parseRealizedVolatilityData(bytes memory data) internal pure returns (RealizedVolatility memory) {
        RealizedVolatility memory entry;
        uint256 index = 0;

        (entry.metadata, index) = parseMetadata(data, index);

        entry.volatility = data.toUint256(index);
        index += 32;

        entry.time_period = data.toUint256(index);
        index += 32;

        entry.start_price = data.toUint256(index);
        index += 32;

        entry.end_price = data.toUint256(index);
        index += 32;

        entry.high_price = data.toUint256(index);
        index += 32;

        entry.low_price = data.toUint256(index);
        index += 32;

        entry.number_of_data_points = data.toUint256(index);

        return entry;
    }

    function parseOptionsData(bytes memory data) internal pure returns (Options memory) {
        Options memory entry;
        uint256 index = 0;

        (entry.metadata, index) = parseMetadata(data, index);

        entry.strike_price = data.toUint256(index);
        index += 32;

        entry.implied_volatility = data.toUint256(index);
        index += 32;

        entry.time_to_expiry = data.toUint256(index);
        index += 32;

        entry.is_call = data.toUint8(index) == 1;
        index += 1;

        entry.underlying_price = data.toUint256(index);
        index += 32;

        entry.option_price = data.toUint256(index);
        index += 32;

        entry.delta = data.toInt256(index);
        index += 32;

        entry.gamma = data.toInt256(index);
        index += 32;

        entry.vega = data.toInt256(index);
        index += 32;

        entry.theta = data.toInt256(index);
        index += 32;

        entry.rho = data.toInt256(index);

        return entry;
    }

    function parsePerpData(bytes memory data) internal pure returns (Perp memory) {
        Perp memory entry;
        uint256 index = 0; 

        (entry.metadata, index) = parseMetadata(data, index);

        entry.mark_price = data.toUint256(index);
        index += 32;

        entry.funding_rate = data.toUint256(index);
        index += 32;

        entry.open_interest = data.toUint256(index);
        index += 32;

        entry.volume = data.toUint256(index);

        return entry;
    }
}
