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
import "forge-std/console2.sol";

contract PragmaDecoder {
    using BytesLib for bytes;

    /* STORAGE */
    IHyperlane public immutable hyperlane;

    mapping(bytes32 => DataFeed) public _latestPriceInfo;
    mapping(bytes32 => bool) public _isValidDataSource;
    mapping(bytes32 => uint64) public latestPublishTimes;

    mapping(bytes => SpotMedian) public spotMedianFeeds;
    mapping(bytes => TWAP) public twapFeeds;
    mapping(bytes => RealizedVolatility) public rvFeeds;
    mapping(bytes => Options) public optionsFeeds;
    mapping(bytes => Perp) public perpFeeds;

    constructor(
        address _hyperlane,
        uint16[] memory _dataSourceEmitterChainIds,
        bytes32[] memory _dataSourceEmitterAddresses
    ) {
        hyperlane = IHyperlane(payable(_hyperlane));

        for (uint256 i = 0; i < _dataSourceEmitterChainIds.length; i++) {
            _isValidDataSource[keccak256(
                abi.encodePacked(_dataSourceEmitterChainIds[i], _dataSourceEmitterAddresses[i])
            )] = true;
        }
    }

    // TODO: set valid data sources
    function isValidDataSource(uint16 chainId, bytes32 emitterAddress) public view returns (bool) {
        return _isValidDataSource[keccak256(abi.encodePacked(chainId, emitterAddress))];
    }

    function parseAndVerifyHyMsg(bytes calldata encodedHyMsg) internal view returns (HyMsg memory hyMsg, uint256 index) {
        {
            bool valid;
            (hyMsg, valid,, index) = hyperlane.parseAndVerifyHyMsg(encodedHyMsg);
            if (!valid) revert ErrorsLib.InvalidHyperlaneCheckpointRoot();
        }

        if (!isValidDataSource(hyMsg.emitterChainId, hyMsg.emitterAddress)) {
            revert ErrorsLib.InvalidUpdateDataSource();
        }
    }


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
                    (HyMsg memory hyMsg, uint256 index) = parseAndVerifyHyMsg(UnsafeCalldataBytesLib.slice(encoded, offset, hyMsgSize));
                    encodedPayload = hyMsg.payload;
                    offset +=index;
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


    function _isProofValid(
        bytes calldata encodedProof,
        uint256 offset,
        bytes32 root,
        bytes calldata leafData
    ) internal virtual returns (bool valid, uint256 endOffset) {
        return MerkleTree.isProofValid(encodedProof, offset, root, leafData);
    }

    function extractDataInfoFromUpdate(bytes calldata encoded, uint256 offset, bytes32 checkpointRoot)
        internal 
        returns (uint256 endOffset, ParsedData memory parsedData)
    {
        unchecked {
            bytes calldata encodedUpdate;
            bytes calldata encodedProof;
            bytes calldata fulldataFeed;
            bytes calldata payload = UnsafeCalldataBytesLib.slice(encoded, offset, encoded.length - offset);
            uint256 payloadOffset =33;  // skip checkpoint root and num Updates
            uint16 updateSize = UnsafeCalldataBytesLib.toUint16(payload, payloadOffset);
            payloadOffset +=2;
            uint16 proofSize = UnsafeCalldataBytesLib.toUint16(payload, payloadOffset);
            payloadOffset +=2;
            offset +=payloadOffset + updateSize;
            {
                encodedProof = UnsafeCalldataBytesLib.slice(payload, payloadOffset, proofSize);
                payloadOffset +=proofSize;
                encodedUpdate = UnsafeCalldataBytesLib.slice(payload, payloadOffset, updateSize);
                fulldataFeed = UnsafeCalldataBytesLib.slice(payload, payloadOffset, payload.length - payloadOffset);
                payloadOffset += updateSize;
            }
           

            bool valid;
            (valid, endOffset) = _isProofValid(encodedProof, offset,checkpointRoot, encodedUpdate);
            if (!valid) revert ErrorsLib.InvalidHyperlaneCheckpointRoot();
            parsedData = parseDataFeed(fulldataFeed);
            endOffset +=40;
        }
    }

    function parseDataFeed(bytes calldata encodedDataFeed)
        private
        pure
        returns (ParsedData memory parsedData)
    {
        parsedData = DataParser.parse(encodedDataFeed);

        // // Assuming dataId and publishTime are appended at the end of encodedDataFeed
        // uint256 offset = encodedDataFeed.length - 40; // 32 bytes for dataId, 8 bytes for publishTime
        // dataId = bytes32(UnsafeCalldataBytesLib.toUint256(encodedDataFeed, offset));
        // offset += 32;
        // publishTime = UnsafeCalldataBytesLib.toUint64(encodedDataFeed, offset);
    }

    function updateDataInfoFromUpdate(bytes calldata updateData) internal returns (uint8 numUpdates) {
        // Extract header metadata
        uint256 encodedOffset = extractMetadataFromheader(updateData);

        // Extract merkle root and number of updates from update data.
        uint256 offset;
        bytes32 checkpointRoot;
        bytes calldata encoded;

        (offset, checkpointRoot, numUpdates, encoded) = extractCheckpointRootAndNumUpdates(updateData, encodedOffset);
        unchecked {
            for (uint256 i = 0; i < numUpdates; i++) {
                ParsedData memory parsedData;
                bytes32 dataId;
                uint64 publishTime;
                (offset, parsedData) = extractDataInfoFromUpdate(encoded, offset, checkpointRoot);
                updateLatestDataInfoIfNecessary( parsedData, publishTime);
            }
        }
        // We check that the offset is at the end of the encoded data.
        // If not it means the data is not encoded correctly.
        if (offset != encoded.length) revert ErrorsLib.InvalidUpdateData();
    }

   function updateLatestDataInfoIfNecessary(ParsedData memory parsedData) internal {
    (bytes32 feed_id, uint64 timestamp, address feedStorage) = getFeedInfo(parsedData);

    if (timestamp > latestPublishTimes[feed_id]) {
        latestPublishTimes[feed_id] = timestamp;
        assembly {
            sstore(add(feedStorage, feed_id), mload(add(parsedData, 0x20)))
        }
        emitUpdateEvent(parsedData, feed_id, timestamp);
    }
}

function getFeedInfo(ParsedData memory parsedData) private view returns (bytes memory, uint64, address) {
    if (parsedData.dataType == FeedType.SpotMedian) return (parsedData.spot.metadata.feed_id, parsedData.spot.metadata.timestamp, address(spotMedianFeeds));
    if (parsedData.dataType == FeedType.Twap) return (parsedData.twap.metadata.feed_id, parsedData.twap.metadata.timestamp, address(twapFeeds));
    if (parsedData.dataType == FeedType.RealizedVolatility) return (parsedData.rv.metadata.feed_id, parsedData.rv.metadata.timestamp, address(rvFeeds));
    if (parsedData.dataType == FeedType.Options) return (parsedData.options.metadata.feed_id, parsedData.options.metadata.timestamp, address(optionsFeeds));
    if (parsedData.dataType == FeedType.Perpetuals) return (parsedData.perp.metadata.feed_id, parsedData.perp.metadata.timestamp, address(perpFeeds));
    revert ErrorsLib.InvalidDataFeedType();
}

function emitUpdateEvent(ParsedData memory parsedData, bytes32 feed_id, uint64 timestamp) private {
    if (parsedData.dataType == FeedType.SpotMedian) emit EventsLib.SpotMedianUpdate(feed_id, timestamp, parsedData.spot);
    else if (parsedData.dataType == FeedType.Twap) emit EventsLib.TWAPUpdate(feed_id, timestamp, parsedData.twap);
    else if (parsedData.dataType == FeedType.RealizedVolatility) emit EventsLib.RealizedVolatilityUpdate(feed_id, timestamp, parsedData.rv);
    else if (parsedData.dataType == FeedType.Options) emit EventsLib.OptionsUpdate(feed_id, timestamp, parsedData.options);
    else if (parsedData.dataType == FeedType.Perpetuals) emit EventsLib.PerpUpdate(feed_id, timestamp, parsedData.perp);
}
}
