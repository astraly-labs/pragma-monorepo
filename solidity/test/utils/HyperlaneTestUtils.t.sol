// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "../../src/Hyperlane.sol";
import {IHyperlane, HyMsg, Signature} from "../../src/interfaces/IHyperlane.sol";
import "forge-std/Test.sol";

abstract contract HyperlaneTestUtils is Test {
    uint256[] currentSigners;
    uint16 constant CHAIN_ID = 2; // Ethereum
    address hyperlaneAddr;

    function setUpHyperlane(uint8 numValidators) public returns (address) {
        address[] memory initSigners = new address[](numValidators);
        currentSigners = new uint256[](numValidators);

        for (uint256 i = 0; i < numValidators; ++i) {
            currentSigners[i] = i + 1;
            initSigners[i] = vm.addr(currentSigners[i]); // i+1 is the private key for the i-th signer.
        }

        Hyperlane hyperlane_ = new Hyperlane(initSigners);
        return address(hyperlane_);
    }

    function isNotMatch(bytes memory a, bytes memory b) public pure returns (bool) {
        return keccak256(a) != keccak256(b);
    }

    function generateUpdateData(
        uint64 timestamp,
        uint16 emitterChainId,
        bytes32 emitterAddress,
        bytes memory payload,
        uint8 numSigners
    ) public view returns (bytes memory updateData) {
        // TODO: generate update data
    }
}

contract HyperlaneTestUtilsTest is Test, HyperlaneTestUtils {
    uint32 constant TEST_UPDATE_TIMESTAMP = 112;
    uint16 constant TEST_EMITTER_CHAIN_ID = 7;
    bytes32 constant TEST_EMITTER_ADDR = 0x0000000000000000000000000000000000000000000000000000000000000bad;
    bytes constant TEST_PAYLOAD = hex"deadbeaf";
    uint8 constant TEST_NUM_SIGNERS = 4;

    function assertHyMsgMatchesTestValues(HyMsg memory hyMsg, bool valid, string memory reason, bytes memory updateData)
        private
        view
    {
        assertTrue(valid);
        assertEq(reason, "");
        assertEq(hyMsg.timestamp, TEST_UPDATE_TIMESTAMP);
        assertEq(hyMsg.emitterChainId, TEST_EMITTER_CHAIN_ID);
        assertEq(hyMsg.emitterAddress, TEST_EMITTER_ADDR);
        assertEq(hyMsg.payload, TEST_PAYLOAD);
        // parseAndVerifyHyMsg() returns an empty signatures array for gas savings since it's not used
        // after its been verified. parseHyMsg() returns the full signatures array.
        hyMsg = IHyperlane(hyperlaneAddr).parseHyMsg(updateData);
        assertEq(hyMsg.signatures.length, TEST_NUM_SIGNERS);
    }

    function testGenerateUpdateDataWorks() public {
        IHyperlane hyperlane = IHyperlane(setUpHyperlane(5));

        bytes memory updateData = generateUpdateData(
            TEST_UPDATE_TIMESTAMP, TEST_EMITTER_CHAIN_ID, TEST_EMITTER_ADDR, TEST_PAYLOAD, TEST_NUM_SIGNERS
        );

        (HyMsg memory hyMsg, bool valid, string memory reason) = hyperlane.parseAndVerifyHyMsg(updateData);
        assertHyMsgMatchesTestValues(hyMsg, valid, reason, updateData);
    }
}
