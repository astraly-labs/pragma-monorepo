// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../src/Pragma.sol";
import "../../src/libraries/MerkleTree.sol";
import "./RandTestUtils.t.sol";
import "./HyperlaneTestUtils.t.sol";
import {DataFeedType} from "../../src/interfaces/IPragma.sol";
import "../utils/TestConstants.sol";

abstract contract PragmaTestUtils is Test, RandTestUtils, HyperlaneTestUtils {
    uint32 constant SOURCE_EMITTER_CHAIN_ID = 0x1;
    bytes32 constant SOURCE_EMITTER_ADDRESS = 0x03dA250675D8c2BB7cef7E1b7FDFe17aA4D5752Ed82A9333e4F9a12b22E521aa;
    uint256 constant SINGLE_UPDATE_FEE_IN_WEI = 1;
    uint256 constant VALID_TIME_PERIOD_IN_SECONDS = 60;
    uint32 constant MOCK_NONCE_VALUE = 1234;
    uint64 constant MOCK_TIMESTAMP_VALUE = 0;

    function setUpPragma(address hyperlane) public returns (address) {
        uint32[] memory emitterChainIds = new uint32[](1);
        bytes32[] memory emitterAddresses = new bytes32[](1);

        emitterChainIds[0] = SOURCE_EMITTER_CHAIN_ID;
        emitterAddresses[0] = SOURCE_EMITTER_ADDRESS;

        Pragma pragma_ = new Pragma();
        pragma_.initialize(
            hyperlane,
            address(this),
            emitterChainIds,
            emitterAddresses,
            VALID_TIME_PERIOD_IN_SECONDS,
            SINGLE_UPDATE_FEE_IN_WEI
        );

        return address(pragma_);
    }

    function singleUpdateFeeInWei() public pure returns (uint256) {
        return SINGLE_UPDATE_FEE_IN_WEI;
    }

    // Utilities to help generating data feed messages and Hyperlane Checkpoints for them

    struct DataFeedMessage {
        bytes32 feedId;
        int64 value;
        int32 expo;
        uint64 publishTime;
        uint64 prevPublishTime;
    }

    struct MerkleUpdateConfig {
        uint8 depth;
        uint8 numSigners;
        uint32 source_chain_id;
        bytes32 source_emitter_address;
        bytes32 merkle_tree_hook_address;
        bytes32 root;
        uint32 checkpoint_index;
        bytes32 message_id;
        bool brokenSignature;
    }

    function encodeDataFeedMessages(DataFeedMessage[] memory dataFeedMessages)
        internal
        pure
        returns (bytes[] memory encodedDataFeedMessages)
    {
        encodedDataFeedMessages = new bytes[](dataFeedMessages.length);

        for (uint256 i = 0; i < dataFeedMessages.length; i++) {
            encodedDataFeedMessages[i] = abi.encodePacked(
                uint8(DataFeedType.SpotMedian),
                dataFeedMessages[i].feedId,
                dataFeedMessages[i].value,
                dataFeedMessages[i].expo,
                dataFeedMessages[i].publishTime,
                dataFeedMessages[i].prevPublishTime
            );
        }
    }

    function generateHyMerkleUpdateWithSource(
        DataFeedMessage[] memory dataFeedMessages,
        MerkleUpdateConfig memory config
    ) internal returns (bytes memory hyMerkleUpdateData) {
        bytes[] memory encodedDataFeedMessages = encodeDataFeedMessages(dataFeedMessages);

        (bytes32 rootDigest, bytes[] memory proofs) = MerkleTree.constructProofs(encodedDataFeedMessages, config.depth);

        bytes memory hyperlanePayload = abi.encodePacked(rootDigest);

        bytes memory updateData = generateUpdateData(
            MOCK_NONCE_VALUE,
            config.source_chain_id,
            config.source_emitter_address,
            config.merkle_tree_hook_address,
            config.root,
            config.checkpoint_index,
            config.message_id,
            hyperlanePayload,
            config.numSigners
        );

        if (config.brokenSignature) {
            uint256 mutPos = getRandUint() % updateData.length;

            // mutate the random position by 1 bit
            updateData[mutPos] = bytes1(uint8(updateData[mutPos]) ^ 1);
        }

        hyMerkleUpdateData = abi.encodePacked(
            TestConstantsLib.MAJOR_VERSION,
            TestConstantsLib.MINOR_VERSION,
            TestConstantsLib.TRAILING_HEADER_SIZE,
            uint16(updateData.length),
            updateData,
            uint8(dataFeedMessages.length)
        );

        for (uint256 i = 0; i < dataFeedMessages.length; i++) {
            hyMerkleUpdateData = abi.encodePacked(
                hyMerkleUpdateData, uint16(encodedDataFeedMessages[i].length), encodedDataFeedMessages[i], proofs[i]
            );
        }
    }
}
