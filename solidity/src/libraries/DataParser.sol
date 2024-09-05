// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BytesLib.sol";
    struct Metadata {
        uint64 timestamp; 
        uint16 number_of_sources;
        uint8 decimals;
    }

    struct SpotMedianEntry {
        Metadata metadata;
        bytes32 pair_id;
        uint256 price;
        uint256 volume;
    }

struct TWAPEntry {
    Metadata metadata;
    bytes32 pair_id;
    uint256 twap_price;
    uint256 time_period; 
    uint256 start_price;
    uint256 end_price;
    uint256 total_volume;
    uint256 number_of_data_points;
}

struct RealizedVolatilityEntry {
    Metadata metadata;
    bytes32 pair_id;
    uint256 volatility; 
    uint256 time_period; 
    uint256 start_price;
    uint256 end_price;
    uint256 high_price;
    uint256 low_price;
    uint256 number_of_data_points;
}

struct OptionsEntry {
    Metadata metadata;
    bytes32 pair_id;
    uint256 strike_price;
    uint256 implied_volatility; 
    uint256 time_to_expiry;
    bool is_call; 
    uint256 underlying_price;
    uint256 option_price;
    uint256 delta; 
    uint256 gamma; 
    uint256 vega;  
    uint256 theta; 
    uint256 rho;   
}

struct PerpEntry {
    Metadata metadata;
    bytes32 pair_id;
    uint256 mark_price;
    uint256 funding_rate; 
    uint256 open_interest;
    uint256 volume;
}

    struct ParsedData {
        uint16 dataType;
        SpotMedianEntry spotEntry;
        TWAPEntry twapEntry;
        RealizedVolatilityEntry rvEntry;
        OptionsEntry optionsEntry;
        PerpEntry perpEntry;
    }
library DataParser {
    using BytesLib for bytes;

    uint16 constant SM = 21325;
    uint16 constant TW = 21591;
    uint16 constant RV = 21078;
    uint16 constant OP = 20304; 
    uint16 constant PP = 20560;

    function parse(bytes memory data) internal pure returns (ParsedData memory) {
        uint16 dataType = data.toUint16(0);

        ParsedData memory parsedData;
        parsedData.dataType = dataType;
        if (dataType == SM) {
            parsedData.spotEntry = parseSpotData(data);
        } else if (dataType == TW) {
            parsedData.twapEntry = parseTWAPData(data);
        } else if (dataType == RV) {
            parsedData.rvEntry = parseRealizedVolatilityData(data);
        } else if (dataType == OP) {
            parsedData.optionsEntry = parseOptionsData(data);
        } else if (dataType == PP) {
            parsedData.perpEntry = parsePerpData(data);
        } else {
            revert("Unknown data type");
        }

        return parsedData;
    }

    function parsePairId(bytes memory data, uint256 index) internal pure returns (bytes32 , uint256) {

        bytes32 pairId = bytes32(data.toUint256(index));
        index += 32;
        return (pairId, index);
    }

    function parseMetadata(bytes memory data, uint256 startIndex) internal pure returns (Metadata memory, uint256) {
        Metadata memory metadata;
        uint256 index = startIndex;

        metadata.timestamp = data.toUint64(index);
        index += 8;

        metadata.number_of_sources = uint16(data.toUint16(index));
        index += 2;

        metadata.decimals = uint8(data.toUint8(index));
        index += 1;

        return (metadata, index);
    }

    function parseSpotData(bytes memory data) internal pure returns (SpotMedianEntry memory) {
        SpotMedianEntry memory entry;
        uint256 index = 2; 

        (entry.metadata, index) = parseMetadata(data, index);
        (entry.pair_id, index) = parsePairId(data, index);

        entry.price = data.toUint256(index);
        index += 32;

        entry.volume = data.toUint256(index);

        return entry;
    }

    function parseTWAPData(bytes memory data) internal pure returns (TWAPEntry memory) {
        TWAPEntry memory entry;
        uint256 index = 2;

        (entry.metadata, index) = parseMetadata(data, index);
        (entry.pair_id, index) = parsePairId(data, index);

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

    function parseRealizedVolatilityData(bytes memory data) internal pure returns (RealizedVolatilityEntry memory) {
        RealizedVolatilityEntry memory entry;
        uint256 index = 2;

        (entry.metadata, index) = parseMetadata(data, index);
        (entry.pair_id, index) = parsePairId(data, index);

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

    function parseOptionsData(bytes memory data) internal pure returns (OptionsEntry memory) {
        OptionsEntry memory entry;
        uint256 index = 2; 

        (entry.metadata, index) = parseMetadata(data, index);
        (entry.pair_id, index) = parsePairId(data, index);

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

        entry.delta = data.toUint256(index);
        index += 32;

        entry.gamma = data.toUint256(index);
        index += 32;

        entry.vega = data.toUint256(index);
        index += 32;

        entry.theta = data.toUint256(index);
        index += 32;

        entry.rho = data.toUint256(index);

        return entry;
    }

    function parsePerpData(bytes memory data) internal pure returns (PerpEntry memory) {
        PerpEntry memory entry;
        uint256 index = 2; // Skip data type

        (entry.metadata, index) = parseMetadata(data, index);
        (entry.pair_id, index) = parsePairId(data, index);

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