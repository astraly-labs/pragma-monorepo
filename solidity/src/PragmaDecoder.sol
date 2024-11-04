// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import {DataFeed, DataFeedType} from "./interfaces/IPragma.sol";
import {HyMsg, IHyperlane} from "./interfaces/IHyperlane.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./libraries/ConstantsLib.sol";
import "./libraries/ErrorsLib.sol";
import "./libraries/DataParser.sol";
import "./libraries/EventsLib.sol";
import "./libraries/BytesLib.sol";
import "./libraries/MerkleTree.sol";
import "./libraries/UnsafeCalldataBytesLib.sol";
import "./libraries/UnsafeBytesLib.sol";

abstract contract PragmaDecoder {
    using BytesLib for bytes;

    /* STORAGE */
    IHyperlane public hyperlane; // Hyperlane instance for message parsing and verification
    mapping(bytes32 => bool) public _isValidDataSource; // Stores valid data sources by hash of chain ID and emitter address
    mapping(bytes32 => SpotMedian) public spotMedianFeeds; // Stores Spot Median feed data by feed ID
    mapping(bytes32 => TWAP) public twapFeeds; // Stores TWAP feed data by feed ID
    mapping(bytes32 => RealizedVolatility) public rvFeeds; // Stores Realized Volatility feed data by feed ID
    mapping(bytes32 => Options) public optionsFeeds; // Stores Options feed data by feed ID
    mapping(bytes32 => Perp) public perpFeeds; // Stores Perpetual feed data by feed ID

    /// @notice Checks if the specified chain ID and emitter address correspond to a valid data source.
    /// @param chainId The chain ID of the emitter.
    /// @param emitterAddress The emitter's address.
    /// @return bool True if the source is valid, false otherwise.
    function isValidDataSource(uint32 chainId, bytes32 emitterAddress) public view returns (bool) {
        return _isValidDataSource[keccak256(abi.encodePacked(chainId, emitterAddress))];
    }

    /// @notice Parses, verifies a Hyperlane message and extract the checkpoint root, the hyperlane message and the offset index
    /// @param encodedHyMsg Encoded Hyperlane message.
    /// @return hyMsg Parsed hyperlane structure.
    /// @return index Index of the parsed message in the data.
    /// @return checkpointRoot Root hash of the checkpoint in the Hyperlane message.
    function parseAndVerifyHyMsg(bytes calldata encodedHyMsg)
        internal
        view
        returns (HyMsg memory hyMsg, uint256 index, bytes32 checkpointRoot)
    {
        {
            bool valid;
            string memory reason;
            (hyMsg, valid, reason, index, checkpointRoot) = hyperlane.parseAndVerifyHyMsg(encodedHyMsg);
            if (!valid) revert ErrorsLib.InvalidHyperlaneSignatures(reason);
        }

        if (!isValidDataSource(hyMsg.emitterChainId, hyMsg.emitterAddress)) {
            revert ErrorsLib.InvalidUpdateDataSource();
        }
    }

    /// @notice Extracts and validates metadata from the header of update data.
    /// @param updateData The data containing update information.
    /// @param offset The cursor initial position in the data.
    /// @return uint256 The updated offset after metadata extraction.
    function extractMetadataFromheader(bytes calldata updateData, uint256 offset) internal pure returns (uint256) {
        unchecked {
            {
                uint8 majorVersion = UnsafeCalldataBytesLib.toUint8(updateData, offset);

                offset += 1;

                if (majorVersion != ConstantsLib.MAJOR_VERSION) {
                    revert ErrorsLib.InvalidVersion();
                }

                uint8 minorVersion = UnsafeCalldataBytesLib.toUint8(updateData, offset);

                offset += 1;

                // Minor versions are forward compatible, so we only check
                // that the minor version is not less than the minimum allowed
                if (minorVersion < ConstantsLib.MINIMUM_ALLOWED_MINOR_VERSION) {
                    revert ErrorsLib.InvalidVersion();
                }

                // This field ensure that we can add headers in the future
                // without breaking the contract (future compatibility)
                uint8 trailingHeaderSize = UnsafeCalldataBytesLib.toUint8(updateData, offset);
                offset += 1;

                offset += trailingHeaderSize;
            }

            if (updateData.length < offset) {
                revert ErrorsLib.InvalidUpdateData();
            }
        }
        return offset;
    }

    /// @notice Extracts the checkpoint root and number of updates from the update data.
    /// @param updateData The data containing update information.
    /// @param offset The cursor position.
    /// @return uint256 The updated cursor position after extraction.
    /// @return checkpointRoot The Merkle root of the checkpoint.
    /// @return numUpdates The number of updates in the payload.
    function extractCheckpointRootAndNumUpdates(bytes calldata updateData, uint256 offset)
        internal
        view
        returns (uint256, bytes32 checkpointRoot, uint8 numUpdates)
    {
        unchecked {
            // Get the size of the hyperlane message
            uint16 hyMsgSize = UnsafeCalldataBytesLib.toUint16(updateData, offset);
            offset += 2;

            // Extract and verify the hyperlane message
            bytes calldata hyMsgData = UnsafeCalldataBytesLib.slice(updateData, offset, hyMsgSize);
            (HyMsg memory hyMsg, uint256 index, bytes32 root) = parseAndVerifyHyMsg(hyMsgData);

            // Set the checkpoint root and get the payload
            checkpointRoot = root;
            bytes memory encodedPayload = hyMsg.payload;
            offset += index;

            // Extract the number of updates from the payload
            numUpdates = UnsafeBytesLib.toUint8(encodedPayload, 0);
            offset += 1;
        }
        return (offset, checkpointRoot, numUpdates);
    }

    function _isProofValid(bytes calldata encodedProof, uint256 offset, bytes32 root, bytes calldata leafData)
        internal
        virtual
        returns (bool valid, uint256)
    {
        // TODO: The proof is ignored for now until we figure out how to get it from Hyperlane.

        // (valid, endOffset) = MerkleTree.isProofValid(encodedProof, offset, root, leafData);
        return (true, offset);
    }

    /// @notice Extracts feed data information from the update data.
    /// @param updateData The data containing update information.
    /// @param offset The cursor initial position in the data.
    /// @param checkpointRoot The Merkle root to verify data.
    /// @return endOffset The updated cursor position after processing data.
    /// @return parsedData The parsed data structure.
    /// @return feedId Unique identifier of the data feed.
    /// @return publishTime The timestamp of the feed data.
    function extractDataInfoFromUpdate(bytes calldata updateData, uint256 offset, bytes32 checkpointRoot)
        internal
        returns (uint256 endOffset, ParsedData memory parsedData, bytes32 feedId, uint64 publishTime)
    {
        unchecked {
            bytes calldata encodedUpdate;
            bytes calldata encodedProof;
            bytes calldata fulldataFeed;

            offset += 2;
            uint16 proofSize = UnsafeCalldataBytesLib.toUint16(updateData, offset);
            offset += 2;
            {
                encodedProof = UnsafeCalldataBytesLib.slice(updateData, offset, proofSize);
                uint256 encodedUpdateIndex = offset + proofSize;
                encodedUpdate = UnsafeCalldataBytesLib.slice(
                    updateData, encodedUpdateIndex, updateData.length - 40 - encodedUpdateIndex
                ); // 32 bytes for feedId, 8 bytes for publishTime
                fulldataFeed =
                    UnsafeCalldataBytesLib.slice(updateData, encodedUpdateIndex, updateData.length - encodedUpdateIndex);
            }
            // For now, no proof check
            // bool valid;
            // (valid, offset) = _isProofValid(updateData, offset, checkpointRoot, encodedUpdate);
            // if (!valid) revert ErrorsLib.InvalidHyperlaneCheckpointRoot();

            offset += proofSize;
            (parsedData, feedId, publishTime) = parseDataFeed(fulldataFeed);
            endOffset = offset + fulldataFeed.length;
        }
    }

    /// @notice Parses data feed to extract essential information.
    /// @param encodedDataFeed Encoded data feed.
    /// @return parsedData Parsed feed data.
    /// @return feedId Unique feed identifier.
    /// @return publishTime Timestamp of the feed data.
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

    /// @notice Processes update data and applies necessary data feed updates.
    /// @param updateData The data containing update information.
    /// @return numUpdates Number of updates processed.
    function updateDataInfoFromUpdate(bytes calldata updateData) internal returns (uint8 numUpdates) {
        uint256 offset = 0;

        // Extract header metadata
        offset = extractMetadataFromheader(updateData, offset);
        // Extract merkle root and number of updates from update data.
        
        bytes32 checkpointRoot;

        (offset, checkpointRoot, numUpdates) = extractCheckpointRootAndNumUpdates(updateData, offset);

        unchecked {
            for (uint256 i = 0; i < numUpdates; i++) {
                ParsedData memory parsedData;
                bytes32 feedId;
                uint64 publishTime;
                (offset, parsedData, feedId, publishTime) =
                    extractDataInfoFromUpdate(updateData, offset, checkpointRoot);
                updateLatestDataInfoIfNecessary(feedId, parsedData, publishTime);
            }
        }
        // We check that the offset is at the end of the encoded data.
        // If not it means the data is not encoded correctly.
        if (offset != updateData.length) revert ErrorsLib.InvalidUpdateData();
    }

    /// @notice Updates feed data if the publish time is newer than the current stored data.
    /// @param feedId Unique feed identifier.
    /// @param parsedData Parsed data to be stored.
    /// @param publishTime Timestamp of the parsed data.
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
