// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BytesLib.sol";
import "../interfaces/PragmaStructs.sol";
import "./ErrorsLib.sol";

/**
 * @title DataParser
 * @dev A library for parsing data related to different feed types like SpotMedian, TWAP, RealizedVolatility, Options, and Perpetuals.
 *      This library provides functions to extract relevant information from a raw byte array.
 *
 * @notice The data input is expected to be in a specific byte format depending on the feed type. 
 *         Each function in the library parses a specific feed type from the byte array.
 */
library DataParser {
    using BytesLib for bytes;

    /**
     * @dev Parses a raw byte array into `ParsedData` based on the detected `FeedType`.
     * @param data A byte array representing the raw feed data.
     * @return parsedData A `ParsedData` struct containing the parsed data for the specific feed type.
     *
     * The format of `data` is:
     * - `offset`: 2 bytes reserved for identifying the feed type.
     * - The remaining bytes are feed-specific, and the parsing is delegated to other functions based on the feed type.
     */
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

    /**
     * @dev Casts a uint16 value to the `FeedType` enum. Reverts if the value is invalid.
     * @param rawDataType The raw uint16 value representing the feed type.
     * @return A valid `FeedType` enum value.
     */
     function safeCastToFeedType(uint16 rawDataType) internal pure returns (FeedType) {
        if (rawDataType <= uint16(type(FeedType).max)) {
            return FeedType(rawDataType);
        } else {
            revert ErrorsLib.InvalidDataFeedType();
        }
    }

    /**
     * @dev Parses metadata common to all feeds from the byte array.
     * @param data A byte array containing the feed data.
     * @param startIndex The starting index for parsing metadata.
     * @return metadata A `Metadata` struct containing parsed metadata information.
     * @return index The next index after parsing the metadata.
     *
     * Metadata format:
     * - `feedId`: 32 bytes (bytes32)
     * - `timestamp`: 8 bytes (uint64)
     * - `numberOfSources`: 2 bytes (uint16)
     * - `decimals`: 1 byte (uint8)
     */
    function parseMetadata(bytes memory data, uint256 startIndex) internal pure returns (Metadata memory, uint256) {
        Metadata memory metadata;
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


    /**
     * @dev Parses `SpotMedian` feed data from a byte array.
     * @param data A byte array containing the SpotMedian feed data.
     * @return A `SpotMedian` struct containing the parsed SpotMedian data.
     *
     * SpotMedian data format:
     * - Metadata (parsed separately)
     * - `price`: 32 bytes (uint256)
     * - `volume`: 32 bytes (uint256)
     */
    function parseSpotData(bytes memory data) internal pure returns (SpotMedian memory) {
        SpotMedian memory entry;
        uint256 index = 0;

        (entry.metadata, index) = parseMetadata(data, index);

        entry.price = data.toUint256(index);
        index += 32;

        entry.volume = data.toUint256(index);

        return entry;
    }

      /**
     * @dev Parses `TWAP` (Time-Weighted Average Price) feed data from a byte array.
     * @param data A byte array containing the TWAP feed data.
     * @return A `TWAP` struct containing the parsed TWAP data.
     *
     * TWAP data format:
     * - Metadata (parsed separately)
     * - `twapPrice`: 32 bytes (uint256)
     * - `timePeriod`: 32 bytes (uint256)
     * - `startPrice`: 32 bytes (uint256)
     * - `endPrice`: 32 bytes (uint256)
     * - `totalVolume`: 32 bytes (uint256)
     * - `numberOfDataPoints`: 32 bytes (uint256)
     */
    function parseTWAPData(bytes memory data) internal pure returns (TWAP memory) {
        TWAP memory entry;
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

       /**
     * @dev Parses `RealizedVolatility` feed data from a byte array.
     * @param data A byte array containing the RealizedVolatility feed data.
     * @return A `RealizedVolatility` struct containing the parsed realized volatility data.
     *
     * RealizedVolatility data format:
     * - Metadata (parsed separately)
     * - `volatility`: 32 bytes (uint256)
     * - `timePeriod`: 32 bytes (uint256)
     * - `startPrice`: 32 bytes (uint256)
     * - `endPrice`: 32 bytes (uint256)
     * - `high_price`: 32 bytes (uint256)
     * - `low_price`: 32 bytes (uint256)
     * - `numberOfDataPoints`: 32 bytes (uint256)
     */
    function parseRealizedVolatilityData(bytes memory data) internal pure returns (RealizedVolatility memory) {
        RealizedVolatility memory entry;
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

        entry.high_price = data.toUint256(index);
        index += 32;

        entry.low_price = data.toUint256(index);
        index += 32;

        entry.numberOfDataPoints = data.toUint256(index);

        return entry;
    }

     /**
     * @dev Parses `Options` feed data from a byte array.
     * @param data A byte array containing the options feed data.
     * @return An `Options` struct containing the parsed options data.
     *
     * Options data format:
     * - Metadata (parsed separately)
     * - `strikePrice`: 32 bytes (uint256)
     * - `impliedVolatility`: 32 bytes (uint256)
     * - `timeToExpiry`: 32 bytes (uint256)
     * - `isCall`: 1 byte (uint8)
     * - `underlyingPrice`: 32 bytes (uint256)
     * - `optionPrice`: 32 bytes (uint256)
     * - `delta`: 32 bytes (int256)
     * - `gamma`: 32 bytes (int256)
     * - `vega`: 32 bytes (int256)
     * - `theta`: 32 bytes (int256)
     * - `rho`: 32 bytes (int256)
     */
    function parseOptionsData(bytes memory data) internal pure returns (Options memory) {
        Options memory entry;
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

    /**
     * @dev Parses `Perp` (Perpetual) feed data from a byte array.
     * @param data A byte array containing the perpetual feed data.
     * @return A `Perp` struct containing the parsed perpetual data.
     *
     * Perpetual data format:
     * - Metadata (parsed separately)
     * - `markPrice`: 32 bytes (uint256)
     * - `fundingRate`: 32 bytes (uint256)
     * - `openInterest`: 32 bytes (uint256)
     * - `volume`: 32 bytes (uint256)
     */
    function parsePerpData(bytes memory data) internal pure returns (Perp memory) {
        Perp memory entry;
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
