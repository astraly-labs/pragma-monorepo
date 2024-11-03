// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BytesLib.sol";
import "../interfaces/PragmaStructs.sol";
import "./ErrorsLib.sol";

/// @title DataParser Library
/// @notice A library for parsing various data feed types into structured data.
/// @dev This library uses `BytesLib` for handling byte data, and assumes that data is encoded in a specific format.
/// The calldata format can be found on https://docs.pragmaoracle.com/
/// @custom:security-contact security@pragma.build
library DataParser {
    using BytesLib for bytes;

    /// @notice Parses the raw byte data and returns a structured `ParsedData` type.
    /// @dev Determines the feed type based on the data and parses accordingly.
    /// Reverts if the data feed type is invalid.
    /// @param data The raw byte-encoded data to parse.
    /// @return ParsedData struct containing the parsed data.
    function parse(bytes memory data) internal pure returns (ParsedData memory) {
        // Each update data has a feedId as first 31-bytes (and stored as 32-bytes). The two first bytes are allocated to the asset class.
        // The two next bytes are respectively for the feed type and the feed type variant. Finally the remaining 27 bytes are allocated to the
        // pair id. In order to retrieve the feed type, we need to skip the first 2 bytes.
        uint8 offset = 2; // skips the asset class.

        // Extract the feed type
        uint8 rawDataType = data.toUint8(offset);
        FeedType dataType = safeCastToFeedType(rawDataType);
        ParsedData memory parsedData = StructsInitializers.initializeParsedData();
        parsedData.dataType = dataType;

        // Fill the storage  based on the feed type
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

    /// @notice Safely casts a raw data type value to `FeedType`.
    /// @dev Reverts if the raw data type exceeds the maximum value of `FeedType`.
    /// @param rawDataType The raw data type byte.
    /// @return FeedType The casted `FeedType`.
    function safeCastToFeedType(uint8 rawDataType) internal pure returns (FeedType) {
        if (rawDataType <= uint8(type(FeedType).max)) {
            return FeedType(rawDataType);
        } else {
            revert ErrorsLib.InvalidDataFeedType();
        }
    }

    /// @notice Parses metadata information from the byte data starting at a given index.
    /// @param data The raw byte-encoded data.
    /// @param startIndex The starting index for metadata parsing.
    /// @return metadata The parsed `Metadata` structure.
    /// @return index The updated index after parsing metadata.
    function parseMetadata(bytes memory data, uint256 startIndex) internal pure returns (Metadata memory, uint256) {
        Metadata memory metadata = StructsInitializers.initializeMetadata();
        uint256 index = startIndex;

        metadata.feedId = bytes32(data.toUint256(index));
        index += 32;

        metadata.timestamp = data.toUint64(index);
        index += 8;

        metadata.numberOfSources = uint16(data.toUint16(index));
        index += 2;

        metadata.decimals = uint8(data.toUint8(index));
        index += 1;

        return (metadata, index);
    }

    /// @notice Parses SpotMedian data from the byte data.
    /// @param data The raw byte-encoded data.
    /// @return SpotMedian A `SpotMedian` struct with parsed data.
    function parseSpotData(bytes memory data) internal pure returns (SpotMedian memory) {
        SpotMedian memory entry = StructsInitializers.initializeSpotMedian();
        uint256 index = 0;

        (entry.metadata, index) = parseMetadata(data, index);

        entry.price = data.toUint256(index);
        index += 32;

        entry.volume = data.toUint256(index);
        index += 32;

        return entry;
    }

    /// @notice Parses TWAP (Time-Weighted Average Price) data from the byte data.
    /// @param data The raw byte-encoded data.
    /// @return TWAP A `TWAP` struct with parsed data.
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

    /// @notice Parses realized volatility data from the byte data.
    /// @param data The raw byte-encoded data.
    /// @return RealizedVolatility A `RealizedVolatility` struct with parsed data.
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

    /// @notice Parses options data from the byte data.
    /// @param data The raw byte-encoded data.
    /// @return Options An `Options` struct with parsed data.
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

    /// @notice Parses perpetuals data from the byte data.
    /// @param data The raw byte-encoded data.
    /// @return Perp A `Perp` struct with parsed data.
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
