// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BytesLib.sol";
import "../interfaces/PragmaStructs.sol";
import "./ErrorsLib.sol";

library DataParser {
    using BytesLib for bytes;

    function parse(bytes memory data) internal pure returns (ParsedData memory) {
        uint8 offset = 2; // type of feed after the asset class
        uint8 rawDataType = data.toUint8(offset);
        FeedType dataType = safeCastToFeedType(rawDataType);
        ParsedData memory parsedData = StructsInitializers.initializeParsedData();
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

    function safeCastToFeedType(uint8 rawDataType) internal pure returns (FeedType) {
        if (rawDataType <= uint8(type(FeedType).max)) {
            return FeedType(rawDataType);
        } else {
            revert ErrorsLib.InvalidDataFeedType();
        }
    }

    function parseMetadata(bytes memory data, uint256 startIndex) internal pure returns (Metadata memory, uint256) {
        Metadata memory metadata = StructsInitializers.initializeMetadata();
        uint256 index = startIndex;

        uint128 feedIdLow = data.toUint128(index);
        index += 16;
        uint128 feedIdHigh = data.toUint128(index);
        index += 16;

        metadata.feedId = bytes32((uint256(feedIdHigh) << 128) | uint256(feedIdLow));

        metadata.timestamp = data.toUint64(index);
        index += 8;

        metadata.numberOfSources = uint16(data.toUint16(index));
        index += 2;

        metadata.decimals = uint8(data.toUint8(index));
        index += 1;

        return (metadata, index);
    }

    function parseSpotData(bytes memory data) internal pure returns (SpotMedian memory) {
        SpotMedian memory entry = StructsInitializers.initializeSpotMedian();
        uint256 index = 0;

        (entry.metadata, index) = parseMetadata(data, index);

        uint128 priceLow = data.toUint128(index);
        index += 16;
        uint128 priceHigh = data.toUint128(index);
        index += 16;

        entry.price = (uint256(priceHigh) << 128) | uint256(priceLow);

        uint128 volumeLow = data.toUint128(index);
        index += 16;
        uint128 volumeHigh = data.toUint128(index);
        index += 16;

        entry.volume = (uint256(volumeHigh) << 128) | uint256(volumeLow);

        return entry;
    }

    function parseTWAPData(bytes memory data) internal pure returns (TWAP memory) {
        TWAP memory entry = StructsInitializers.initializeTwap();
        uint256 index = 0;

        (entry.metadata, index) = parseMetadata(data, index);

        entry.twapPrice = data.toUint256(index);
        index += 32;

        entry.timePeriod = data.toUint256(index);
        index += 32;

        entry.startPrice = data.toUint256(index);
        index += 32;

        entry.endPrice = data.toUint256(index);
        index += 32;

        entry.totalVolume = data.toUint256(index);
        index += 32;

        entry.numberOfDataPoints = data.toUint256(index);

        return entry;
    }

    function parseRealizedVolatilityData(bytes memory data) internal pure returns (RealizedVolatility memory) {
        RealizedVolatility memory entry = StructsInitializers.initializeRV();
        uint256 index = 0;

        (entry.metadata, index) = parseMetadata(data, index);

        entry.volatility = data.toUint256(index);
        index += 32;

        entry.timePeriod = data.toUint256(index);
        index += 32;

        entry.startPrice = data.toUint256(index);
        index += 32;

        entry.endPrice = data.toUint256(index);
        index += 32;

        entry.highPrice = data.toUint256(index);
        index += 32;

        entry.lowPrice = data.toUint256(index);
        index += 32;

        entry.numberOfDataPoints = data.toUint256(index);

        return entry;
    }

    function parseOptionsData(bytes memory data) internal pure returns (Options memory) {
        Options memory entry = StructsInitializers.initializeOptions();
        uint256 index = 0;

        (entry.metadata, index) = parseMetadata(data, index);

        entry.strikePrice = data.toUint256(index);
        index += 32;

        entry.impliedVolatility = data.toUint256(index);
        index += 32;

        entry.timeToExpiry = data.toUint256(index);
        index += 32;

        entry.isCall = data.toUint8(index) == 1;
        index += 1;

        entry.underlyingPrice = data.toUint256(index);
        index += 32;

        entry.optionPrice = data.toUint256(index);
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
        Perp memory entry = StructsInitializers.initializePerpetuals();
        uint256 index = 0;

        (entry.metadata, index) = parseMetadata(data, index);

        entry.markPrice = data.toUint256(index);
        index += 32;

        entry.fundingRate = data.toUint256(index);
        index += 32;

        entry.openInterest = data.toUint256(index);
        index += 32;

        entry.volume = data.toUint256(index);

        return entry;
    }
}
