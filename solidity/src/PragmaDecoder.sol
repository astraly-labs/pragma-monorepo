// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

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
    IHyperlane public hyperlane;
    mapping(bytes32 => bool) public _isValidDataSource;
    mapping(bytes32 => SpotMedian) public spotMedianFeeds;
    mapping(bytes32 => TWAP) public twapFeeds;
    mapping(bytes32 => RealizedVolatility) public rvFeeds;
    mapping(bytes32 => Options) public optionsFeeds;
    mapping(bytes32 => Perp) public perpFeeds;

    // TODO: set valid data sources
    function isValidDataSource(uint32 chainId, bytes32 emitterAddress) public view returns (bool) {
        return _isValidDataSource[keccak256(abi.encodePacked(chainId, emitterAddress))];
    }

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
                    (HyMsg memory hyMsg, uint256 index, bytes32 root) =
                        parseAndVerifyHyMsg(UnsafeCalldataBytesLib.slice(encoded, offset, hyMsgSize));
                    checkpointRoot = root;
                    encodedPayload = hyMsg.payload;
                    offset += index;
                }

                uint256 payloadOffset = 0;

                {
                    // We don't check equality to enable future compatibility.
                    if (payloadOffset > encodedPayload.length) {
                        revert ErrorsLib.InvalidUpdateData();
                    }
                    numUpdates = UnsafeBytesLib.toUint8(encodedPayload, payloadOffset);
                    offset += encodedOffset + 1;
                    payloadOffset += 1;
                }
            }
        }
    }

    function _isProofValid(bytes calldata encodedProof, uint256 offset, bytes32 root, bytes calldata leafData)
        internal
        virtual
        returns (bool valid, uint256 endOffset)
    {
        // TODO: The proof is ignored for now until we figure out how to get it from Hyperlane.

        // (valid, endOffset) = MerkleTree.isProofValid(encodedProof, offset, root, leafData);
        return (true, offset);
    }

    function extractDataInfoFromUpdate(bytes calldata encoded, uint256 offset, bytes32 checkpointRoot)
        internal
        returns (uint256 endOffset, ParsedData memory parsedData, bytes32 feedId, uint64 publishTime)
    {
        unchecked {
            bytes calldata encodedUpdate;
            bytes calldata encodedProof;
            bytes calldata fulldataFeed;

            offset += 2;
            uint16 proofSize = UnsafeCalldataBytesLib.toUint16(encoded, offset);
            offset += 2;
            {
                encodedProof = UnsafeCalldataBytesLib.slice(encoded, offset, proofSize);
                uint256 encodedUpdateIndex = offset + proofSize;
                encodedUpdate =
                    UnsafeCalldataBytesLib.slice(encoded, encodedUpdateIndex, encoded.length - 40 - encodedUpdateIndex); // 32 bytes for feedId, 8 bytes for publishTime
                fulldataFeed =
                    UnsafeCalldataBytesLib.slice(encoded, encodedUpdateIndex, encoded.length - encodedUpdateIndex);
            }
            // bool valid;
            // (valid, offset) = _isProofValid(encoded, offset, checkpointRoot, encodedUpdate);
            // if (!valid) revert ErrorsLib.InvalidHyperlaneCheckpointRoot();
            offset += proofSize;
            (parsedData, feedId, publishTime) = parseDataFeed(fulldataFeed);
            endOffset = offset + fulldataFeed.length;
        }
    }

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
