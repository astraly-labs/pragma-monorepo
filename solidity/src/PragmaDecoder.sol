// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import {DataFeed, DataFeedType} from "./interfaces/IPragma.sol";
import {HyMsg, IHyperlane} from "./interfaces/IHyperlane.sol";
import "./libraries/ConstantsLib.sol";
import "./libraries/ErrorsLib.sol";
import "./libraries/EventsLib.sol";
import "./libraries/BytesLib.sol";
import "./libraries/MerkleTree.sol";
import "./libraries/UnsafeCalldataBytesLib.sol";
import "./libraries/UnsafeBytesLib.sol";

contract PragmaDecoder {
    using BytesLib for bytes;

    /* STORAGE */
    IHyperlane public immutable hyperlane;

    mapping(bytes32 => DataFeed) public _latestPriceInfo;
    mapping(bytes32 => bool) public _isValidDataSource;

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

    function parseAndVerifyHyMsg(bytes calldata encodedHyMsg) internal view returns (HyMsg memory hyMsg) {
        {
            bool valid;
            (hyMsg, valid,) = hyperlane.parseAndVerifyHyMsg(encodedHyMsg);
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
                    HyMsg memory hyMsg = parseAndVerifyHyMsg(UnsafeCalldataBytesLib.slice(encoded, offset, hyMsgSize));
                    offset += hyMsgSize;

                    encodedPayload = hyMsg.payload;
                }

                uint256 payloadOffset = 0;

                {
                    checkpointRoot = UnsafeBytesLib.toBytes32(encodedPayload, payloadOffset);
                    payloadOffset += 32;

                    // We don't check equality to enable future compatibility.
                    if (payloadOffset > encodedPayload.length) {
                        revert ErrorsLib.InvalidUpdateData();
                    }
                }
            }

            numUpdates = UnsafeCalldataBytesLib.toUint8(encoded, offset);
            offset += 1;
        }
    }

    function extractDataInfoFromUpdate(bytes calldata encoded, uint256 offset, bytes32 checkpointRoot)
        internal
        pure
        returns (uint256 endOffset, DataFeed memory dataFeed, bytes32 dataId, uint64 publishTime)
    {
        unchecked {
            bytes calldata encodedUpdate;
            uint16 updateSize = UnsafeCalldataBytesLib.toUint16(encoded, offset);
            offset += 2;

            {
                encodedUpdate = UnsafeCalldataBytesLib.slice(encoded, offset, updateSize);
                offset += updateSize;
            }

            bool valid;
            (valid, endOffset) = MerkleTree.isProofValid(
                encoded, // data
                offset, // where to start reading the proof
                checkpointRoot, // root
                encodedUpdate // leaf
            );

            if (!valid) revert ErrorsLib.InvalidHyperlaneCheckpointRoot();

            DataFeedType dataFeedType = DataFeedType(UnsafeCalldataBytesLib.toUint8(encodedUpdate, 0));
            if (dataFeedType == DataFeedType.SpotMedian) {
                (dataFeed, dataId, publishTime) = parseSpotMedianDataFeed(encodedUpdate, 1);
            } else {
                revert ErrorsLib.InvalidDataFeedType();
            }
        }
    }

    function parseSpotMedianDataFeed(bytes calldata encodedDataFeed, uint256 offset)
        private
        pure
        returns (DataFeed memory dataFeedInfo, bytes32 dataId, uint64 publishTime)
    {
        unchecked {
            // TODO: parse the spot median data feed
        }
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
                DataFeed memory dataFeed;
                bytes32 dataId;
                (offset, dataFeed, dataId,) = extractDataInfoFromUpdate(encoded, offset, checkpointRoot);
                updateLatestDataInfoIfNecessary(dataId, dataFeed);
            }
        }

        // We check that the offset is at the end of the encoded data.
        // If not it means the data is not encoded correctly.
        if (offset != encoded.length) revert ErrorsLib.InvalidUpdateData();
    }

    function updateLatestDataInfoIfNecessary(bytes32 dataId, DataFeed memory info) internal {
        uint64 latestPublishTime = _latestPriceInfo[dataId].publishTime;
        if (info.publishTime > latestPublishTime) {
            _latestPriceInfo[dataId] = info;
            emit EventsLib.DataFeedUpdate(dataId, info.publishTime, info.numSourcesAggregated, info.value);
        }
    }
}
