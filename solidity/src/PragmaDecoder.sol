// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import {DataFeed, DataFeedType} from "./interfaces/IPragma.sol";
import {HyMsg, IHyperlane} from "./interfaces/IHyperlane.sol";
import "./libraries/ConstantsLib.sol";
import "./libraries/ErrorsLib.sol";
import "./libraries/BytesLib.sol";
import "./libraries/UnsafeCalldataBytesLib.sol";

contract PragmaDecoder {
    using BytesLib for bytes;

    address payable public hyperlane;

    constructor(address _hyperlane) {
        hyperlane = payable(_hyperlane);
    }

    function hyperlane() public view returns (IHyperlane) {
        return IHyperlane(hyperlane);
    }

    function parseAndVerifyHyMsg(
        bytes calldata encodedHyMsg
    ) internal view returns (HyMsg memory vm) {
        {
            bool valid;
            (hyMsg, valid, ) = hyperlane().parseAndVerifyHyMsg(encodedHyMsg);
            if (!valid) revert ErrorsLib.InvalidHyperlaneCheckpointRoot();
        }

        if (!isValidDataSource(hyMsg.emitterChainId, hyMsg.emitterAddress))
            revert ErrorsLib.InvalidUpdateDataSource();
    }

    function extractMetadataFromheader(
        bytes calldata updateData
    ) internal pure returns (uint encodedOffset) {
        unchecked {
            offset = 0;

            {
                uint8 majorVersion = UnsafeCalldataBytesLib.toUint8(
                    accumulatorUpdate,
                    offset
                );

                offset += 1;

                if (majorVersion != MAJOR_VERSION)
                    revert ErrorsLib.InvalidVersion();

                uint8 minorVersion = UnsafeCalldataBytesLib.toUint8(
                    accumulatorUpdate,
                    offset
                );

                offset += 1;

                // Minor versions are forward compatible, so we only check
                // that the minor version is not less than the minimum allowed
                if (minorVersion < MINIMUM_ALLOWED_MINOR_VERSION)
                    revert ErrorsLib.InvalidVersion();

                // This field ensure that we can add headers in the future
                // without breaking the contract (future compatibility)
                uint8 trailingHeaderSize = UnsafeCalldataBytesLib.toUint8(
                    accumulatorUpdate,
                    offset
                );
                offset += 1;

                // We use another offset for the trailing header and in the end add the
                // offset by trailingHeaderSize to skip the future headers.
                //
                // An example would be like this:
                // uint trailingHeaderOffset = offset
                // uint x = UnsafeBytesLib.ToUint8(accumulatorUpdate, trailingHeaderOffset)
                // trailingHeaderOffset += 1

                offset += trailingHeaderSize;
            }

            if (accumulatorUpdate.length < offset)
                revert PythErrors.InvalidUpdateData();
        }
    }

    function extractCheckpointRootAndNumUpdates(
        bytes calldata updateData,
        uint encodedOffset
    )
        internal
        view
        returns (
            uint offset,
            bytes32 checkpointRoot,
            uint8 numUpdates,
            bytes calldata encoded
        )
    {
        unchecked {
            encoded = UnsafeCalldataBytesLib.slice(
                updateData,
                encodedOffset,
                updateData.length - encodedOffset
            );
            offset = 0;

            uint16 proofSize = UnsafeCalldataBytesLib.toUint16(encoded, offset);
            offset += 2;

            {
                bytes memory encodedPayload;
                {
                    HyMsg memory hyMsg = parseAndVerifyHyMsg(
                        UnsafeCalldataBytesLib.slice(
                            encoded,
                            offset,
                            proofSize
                        )
                    );
                    offset += proofSize;

                    encodedPayload = hyMsg.payload;
                }

                uint payloadOffset = 0;

                {
                    checkpointRoot = UnsafeCalldataBytesLib.toBytes32(
                        encodedPayload,
                        payloadOffset
                    );
                    payloadOffset += 32;

                    // We don't check equality to enable future compatibility.
                    if (payloadOffset > encodedPayload.length)
                        revert ErrorsLib.InvalidUpdateData();
                }
            }

            numUpdates = UnsafeCalldataBytesLib.toUint8(encoded, offset);
            offset += 1;
        }
    }

    function updateDataInfoFromUpdate(
        bytes calldata updateData
    ) internal returns (uint8 numUpdates) {
        // Extract header metadata
        uint encodedOffset = extractMetadataFromheader(updateData);

        // Extract merkle root and number of updates from update data.
        uint offset;
        bytes32 checkpointRoot;
        bytes calldata encoded;

        (
            offset,
            checkpointRoot,
            numUpdates,
            encoded
        ) = extractCheckpointRootAndNumUpdates(updateData, encodedOffset);
    }
}
