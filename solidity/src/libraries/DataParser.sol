// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BytesLib.sol";
import "../interfaces/PragmaStructs.sol";
import "./ErrorsLib.sol";

library DataParser {
    using BytesLib for bytes;

    function parse(bytes memory data) internal pure returns (ParsedData memory) {
        uint8 offset = 2; // type feed stored after asset class
        uint16 rawDataType = data.toUint16(offset);
        FeedType dataType = safeCastToFeedType(rawDataType);

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
            revert ErrorsLib.InvalidDataFeedType();
        }

        return parsedData;
    }

    function safeCastToFeedType(uint16 rawDataType) internal pure returns (FeedType) {
        if (rawDataType <= uint16(type(FeedType).max)) {
            return FeedType(rawDataType);
        } else {
            revert ErrorsLib.InvalidDataFeedType();
        }
    }

    function parseMetadata(bytes memory data, uint256 startIndex) internal pure returns (Metadata memory, uint256) {
        Metadata memory metadata;
        uint256 index = startIndex;

        metadata.feedId = bytes32(data.toUint256(index));
        index += 32;

        metadata.timestamp = data.toUint32(index);
        index += 4;

        metadata.numberOfSources = uint16(data.toUint16(index));
        index += 2;

        metadata.decimals = uint8(data.toUint8(index));
        index += 1;

        return (metadata, index);
    }

    function parseSpotData(bytes memory data) internal pure returns (SpotMedian memory) {
        SpotMedian memory entry;
        uint256 index = 0;

        (entry.metadata, index) = parseMetadata(data, index);

        entry.price = data.toUint128(index);
        index += 16;

        entry.volume = data.toUint128(index);

        return entry;
    }

    function parseTWAPData(bytes memory data) internal pure returns (TWAP memory) {
        TWAP memory entry;
        uint256 index = 0;

        (entry.metadata, index) = parseMetadata(data, index);

        entry.twapPrice = data.toUint128(index);
        index += 16;

        entry.timePeriod = data.toUint128(index);
        index += 16;

        entry.startPrice = data.toUint128(index);
        index += 16;

        entry.endPrice = data.toUint128(index);
        index += 16;

        entry.totalVolume = data.toUint128(index);
        index += 16;

        entry.numberOfDataPoints = data.toUint128(index);

        return entry;
    }

    function parseRealizedVolatilityData(bytes memory data) internal pure returns (RealizedVolatility memory) {
        RealizedVolatility memory entry;
        uint256 index = 0;

        (entry.metadata, index) = parseMetadata(data, index);

        entry.volatility = data.toUint128(index);
        index += 16;

        entry.timePeriod = data.toUint128(index);
        index += 16;

        entry.startPrice = data.toUint128(index);
        index += 16;

        entry.endPrice = data.toUint128(index);
        index += 16;

        entry.highPrice = data.toUint128(index);
        index += 16;

        entry.lowPrice = data.toUint128(index);
        index += 16;

        entry.numberOfDataPoints = data.toUint128(index);

        return entry;
    }

    function parseOptionsData(bytes memory data) internal pure returns (Options memory) {
        Options memory entry;
        uint256 index = 0;

        (entry.metadata, index) = parseMetadata(data, index);

        entry.strikePrice = data.toUint128(index);
        index += 16;

        entry.impliedVolatility = data.toUint128(index);
        index += 16;

        entry.timeToExpiry = data.toUint64(index);
        index += 8;

        entry.isCall = data.toUint8(index) == 1;
        index += 1;

        entry.underlyingPrice = data.toUint128(index);
        index += 16;

        entry.optionPrice = data.toUint128(index);
        index += 16;

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

        entry.markPrice = data.toUint128(index);
        index += 16;

        entry.fundingRate = data.toUint128(index);
        index += 16;

        entry.openInterest = data.toUint128(index);
        index += 16;

        entry.volume = data.toUint128(index);

        return entry;
    }
}
