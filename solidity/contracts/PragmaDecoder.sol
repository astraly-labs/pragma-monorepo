// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import {DataFeed, DataFeedType} from "./interfaces/IPragma.sol";
import {HyMsg, IHyperlane} from "./interfaces/IHyperlane.sol";
import "./libraries/ConstantsLib.sol";
import "./libraries/ErrorsLib.sol";
import "./libraries/DataParser.sol";
import "./libraries/EventsLib.sol";
import "./libraries/BytesLib.sol";
import "./libraries/MerkleTree.sol";
import "./libraries/UnsafeCalldataBytesLib.sol";
import "./libraries/UnsafeBytesLib.sol";

/// @title PragmaDecoder
/// @notice This contract is responsible for decoding, verifying, and processing data feed updates
///         from the Hyperlane protocol. It ensures the integrity of the data through Merkle proofs
///         and verifies the data source's validity. The contract can handle multiple types of data feeds
///         such as spot medians, TWAP (Time-Weighted Average Prices), realized volatility, options, and perpetuals.
contract PragmaDecoder {
    using BytesLib for bytes;

    /* STORAGE */
    /// @notice The Hyperlane contract that provides the messaging layer for data updates.
    IHyperlane public immutable hyperlane;

    /// @notice Mapping to track valid data sources, identified by their chain ID and address.
    mapping(bytes32 => bool) private _isValidDataSource;

    /// @notice Tracks the latest publish times for each data feed to ensure data freshness.
    mapping(bytes32 => uint64) public latestPublishTimes;

    /// @notice Stores the latest Spot Median feed data by feed ID.
    mapping(bytes32 => SpotMedian) public spotMedianFeeds;

    /// @notice Stores the latest TWAP feed data by feed ID.
    mapping(bytes32 => TWAP) public twapFeeds;

    /// @notice Stores the latest Realized Volatility feed data by feed ID.
    mapping(bytes32 => RealizedVolatility) public rvFeeds;

    /// @notice Stores the latest Options feed data by feed ID.
    mapping(bytes32 => Options) public optionsFeeds;

    /// @notice Stores the latest Perpetual feed data by feed ID.
    mapping(bytes32 => Perp) public perpFeeds;

    /* CONSTRUCTOR */

    /// @param _hyperlane The address of the Hyperlane contract used for receiving messages.
    /// @param _dataSourceEmitterChainIds Array of chain IDs representing valid data sources.
    /// @param _dataSourceEmitterAddresses Array of emitter addresses corresponding to valid data sources.
    constructor(
        address _hyperlane,
        uint16[] memory _dataSourceEmitterChainIds,
        bytes32[] memory _dataSourceEmitterAddresses
    ) {
        hyperlane = IHyperlane(payable(_hyperlane));

        for (uint256 i; i < _dataSourceEmitterChainIds.length;) {
            _isValidDataSource[keccak256(
                abi.encodePacked(_dataSourceEmitterChainIds[i], _dataSourceEmitterAddresses[i])
            )] = true;
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Checks if the given chain ID and emitter address form a valid data source.
    /// @param chainId The chain ID of the data source.
    /// @param emitterAddress The address of the data emitter on the given chain.
    /// @return True if the data source is valid, false otherwise.
    function isValidDataSource(uint16 chainId, bytes32 emitterAddress) public view returns (bool) {
        return _isValidDataSource[keccak256(abi.encodePacked(chainId, emitterAddress))];
        // TODO: set valid data sources
    }

    /// @notice Parses and verifies a Hyperlane message, ensuring its integrity and origin.
    /// @param encodedHyMsg The encoded Hyperlane message.
    /// @return hyMsg The decoded Hyperlane message.
    /// @return index The index at which the message ends within the provided data.
    function parseAndVerifyHyMsg(bytes calldata encodedHyMsg)
        internal
        view
        returns (HyMsg memory hyMsg, uint256 index)
    {
        {
            bool valid;
            (hyMsg, valid,, index) = hyperlane.parseAndVerifyHyMsg(encodedHyMsg);
            if (!valid) revert ErrorsLib.InvalidHyperlaneCheckpointRoot();
        }

        if (!isValidDataSource(hyMsg.emitterChainId, hyMsg.emitterAddress)) {
            revert ErrorsLib.InvalidUpdateDataSource();
        }
    }

    /// @notice Extracts metadata from the header of the update data.
    /// @param updateData The encoded update data.
    /// @return encodedOffset The offset within the encoded data after processing the header.
    function extractMetadataFromheader(bytes calldata updateData) internal pure returns (uint256 encodedOffset) {
        unchecked {
            encodedOffset = 0;
            {
                uint8 majorVersion = UnsafeCalldataBytesLib.toUint8(updateData, encodedOffset);

                encodedOffset += 1;

                if (majorVersion != ConstantsLib.MAJOR_VERSION) {
                    revert ErrorsLib.InvalidVersion();
                }

                uint8 minorVersion = UnsafeCalldataBytesLib.toUint8(updateData, encodedOffset);

                encodedOffset += 1;

                // Minor versions are forward compatible, so we only check
                // that the minor version is not less than the minimum allowed
                if (minorVersion < ConstantsLib.MINIMUM_ALLOWED_MINOR_VERSION) {
                    revert ErrorsLib.InvalidVersion();
                }

                // This field ensure that we can add headers in the future
                // without breaking the contract (future compatibility)
                uint8 trailingHeaderSize = UnsafeCalldataBytesLib.toUint8(updateData, encodedOffset);
                encodedOffset += 1;

                // We use another encodedOffset for the trailing header and in the end add the
                // encodedOffset by trailingHeaderSize to skip the future headers.
                //
                // An example would be like this:
                // uint trailingHeaderOffset = encodedOffset
                // uint x = UnsafeBytesLib.ToUint8(updateData, trailingHeaderOffset)
                // trailingHeaderOffset += 1

                encodedOffset += trailingHeaderSize;
            }

            if (updateData.length < encodedOffset) {
                revert ErrorsLib.InvalidUpdateData();
            }
        }
    }

    /// @notice Extracts the Checkpoint root and the number of updates from the update data.
    /// @param updateData The encoded update data.
    /// @param encodedOffset The offset at which to begin extracting data.
    /// @return offset The new offset after extraction.
    /// @return checkpointRoot The Merkle root for the update data.
    /// @return numUpdates The number of updates contained within the data.
    /// @return encoded The remaining encoded update data after processing.
    function extractCheckpointRootAndNumUpdates(bytes calldata updateData, uint256 encodedOffset)
        internal
        view
        returns (uint256 offset, bytes32 checkpointRoot, uint8 numUpdates, bytes calldata encoded)
    {
        unchecked {
            encoded = UnsafeCalldataBytesLib.slice(updateData, encodedOffset, updateData.length - encodedOffset);
            offset = 0;

            uint16 hyMsgSize = UnsafeCalldataBytesLib.toUint16(encoded, offset);
            offset += 2;

            {
                bytes memory encodedPayload;
                {
                    (HyMsg memory hyMsg, uint256 index) =
                        parseAndVerifyHyMsg(UnsafeCalldataBytesLib.slice(encoded, offset, hyMsgSize));
                    encodedPayload = hyMsg.payload;
                    offset += index;
                }

                uint256 payloadOffset = 0;

                {
                    checkpointRoot = UnsafeBytesLib.toBytes32(encodedPayload, payloadOffset);
                    payloadOffset += 32;

                    // We don't check equality to enable future compatibility.
                    if (payloadOffset > encodedPayload.length) {
                        revert ErrorsLib.InvalidUpdateData();
                    }
                    numUpdates = UnsafeBytesLib.toUint8(encodedPayload, payloadOffset);
                    payloadOffset += 1;
                }
            }
        }
    }

    /// @notice Internal redirection to the MerkleLib library function `isProofValid`
    /// @dev Implemented this function to mock the output in the testing stage.
    function _isProofValid(bytes calldata encodedProof, uint256 offset, bytes32 root, bytes calldata leafData)
        internal
        virtual
        returns (bool valid, uint256 endOffset)
    {
        return MerkleTree.isProofValid(encodedProof, offset, root, leafData);
    }

    /// @notice Extracts data and proof information from the provided update data and verifies its integrity.
    /// @param encoded The encoded update data.
    /// @param offset The offset at which to begin extracting.
    /// @param checkpointRoot The Merkle root to verify against.
    /// @return endOffset The new offset after extracting data.
    /// @return parsedData The parsed data feed information.
    /// @return feedId The unique identifier of the data feed.
    /// @return publishTime The timestamp of the data feed update.
    function extractDataInfoFromUpdate(bytes calldata encoded, uint256 offset, bytes32 checkpointRoot)
        internal
        returns (uint256 endOffset, ParsedData memory parsedData, bytes32 feedId, uint64 publishTime)
    {
        unchecked {
            bytes calldata encodedUpdate;
            bytes calldata encodedProof;
            bytes calldata fulldataFeed;
            bytes calldata payload = UnsafeCalldataBytesLib.slice(encoded, offset, encoded.length - offset);
            uint256 payloadOffset = 33; // skip checkpoint root and num Updates
            uint16 updateSize = UnsafeCalldataBytesLib.toUint16(payload, payloadOffset);
            payloadOffset += 2;
            uint16 proofSize = UnsafeCalldataBytesLib.toUint16(payload, payloadOffset);
            payloadOffset += 2;
            offset += payloadOffset + updateSize;
            {
                encodedProof = UnsafeCalldataBytesLib.slice(payload, payloadOffset, proofSize);
                payloadOffset += proofSize;
                encodedUpdate = UnsafeCalldataBytesLib.slice(payload, payloadOffset, updateSize);
                fulldataFeed = UnsafeCalldataBytesLib.slice(payload, payloadOffset, payload.length - payloadOffset);
                payloadOffset += updateSize;
            }

            bool valid;
            (valid, endOffset) = _isProofValid(encodedProof, offset, checkpointRoot, encodedUpdate);
            if (!valid) revert ErrorsLib.InvalidHyperlaneCheckpointRoot();
            (parsedData, feedId, publishTime) = parseDataFeed(fulldataFeed);
            endOffset += 40;
        }
    }

    /// @notice Parses a data feed from the provided encoded data and extracts the feed ID and publish time.
    /// @param encodedDataFeed The encoded data feed containing the data, feed ID, and publish time.
    /// @return parsedData The parsed data from the encoded data feed.
    /// @return feedId The unique identifier of the data feed.
    /// @return publishTime The timestamp of the data feed update.
    function parseDataFeed(bytes calldata encodedDataFeed)
        private
        pure
        returns (ParsedData memory parsedData, bytes32 feedId, uint64 publishTime)
    {
        parsedData = DataParser.parse(encodedDataFeed);

        // Assuming feedId and publishTime are appended at the end of encodedDataFeed
        uint256 offset = encodedDataFeed.length - 40; // 32 bytes for feedId, 8 bytes for publishTime
        feedId = bytes32(UnsafeCalldataBytesLib.toUint256(encodedDataFeed, offset));
        offset += 32;
        publishTime = UnsafeBytesLib.toUint64(encodedDataFeed, offset);
    }

    /// @notice Processes the provided update data and extracts the number of updates, verifying their integrity.
    /// @param updateData The encoded update data, including the Merkle root and feed updates.
    /// @return numUpdates The number of feed updates contained within the provided data.
    function updateDataInfoFromUpdate(bytes calldata updateData) internal returns (uint8 numUpdates) {
        // Extract header metadata
        uint256 encodedOffset = extractMetadataFromheader(updateData);

        // Extract merkle root and number of updates from update data.
        uint256 offset;
        bytes32 checkpointRoot;
        bytes calldata encoded;

        (offset, checkpointRoot, numUpdates, encoded) = extractCheckpointRootAndNumUpdates(updateData, encodedOffset);
        unchecked {
            for (uint256 i = 0; i < numUpdates;) {
                ParsedData memory parsedData;
                bytes32 feedId;
                uint64 publishTime;
                (offset, parsedData, feedId, publishTime) = extractDataInfoFromUpdate(encoded, offset, checkpointRoot);
                updateLatestDataInfoIfNecessary(feedId, parsedData, publishTime);
                ++i;
            }
        }
        // We check that the offset is at the end of the encoded data.
        // If not it means the data is not encoded correctly.
        if (offset != encoded.length) revert ErrorsLib.InvalidUpdateData();
    }

    /// @notice Updates the stored data feeds with new information if the update is more recent than the current data.
    /// @param feedId The ID of the data feed.
    /// @param parsedData The parsed data feed information.
    /// @param publishTime The timestamp of the data feed update.
    function updateLatestDataInfoIfNecessary(bytes32 feedId, ParsedData memory parsedData, uint64 publishTime)
        internal
    {
        if (parsedData.dataType == FeedType.SpotMedian) {
            if (publishTime > spotMedianFeeds[feedId].metadata.timestamp) {
                spotMedianFeeds[feedId] = parsedData.spot;
                emit EventsLib.SpotMedianUpdate(feedId, publishTime, parsedData.spot);
            }
        } else if (parsedData.dataType == FeedType.Twap) {
            if (publishTime > twapFeeds[feedId].metadata.timestamp) {
                twapFeeds[feedId] = parsedData.twap;
                emit EventsLib.TWAPUpdate(feedId, publishTime, parsedData.twap);
            }
        } else if (parsedData.dataType == FeedType.RealizedVolatility) {
            if (publishTime > rvFeeds[feedId].metadata.timestamp) {
                rvFeeds[feedId] = parsedData.rv;
                emit EventsLib.RealizedVolatilityUpdate(feedId, publishTime, parsedData.rv);
            }
        } else if (parsedData.dataType == FeedType.Options) {
            if (publishTime > optionsFeeds[feedId].metadata.timestamp) {
                optionsFeeds[feedId] = parsedData.options;
                emit EventsLib.OptionsUpdate(feedId, publishTime, parsedData.options);
            }
        } else if (parsedData.dataType == FeedType.Perpetuals) {
            if (publishTime > perpFeeds[feedId].metadata.timestamp) {
                perpFeeds[feedId] = parsedData.perp;
                emit EventsLib.PerpUpdate(feedId, publishTime, parsedData.perp);
            }
        } else {
            revert ErrorsLib.InvalidDataFeedType();
        }
    }
}
