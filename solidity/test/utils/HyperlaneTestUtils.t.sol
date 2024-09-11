// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "../../src/Hyperlane.sol";
import {IHyperlane, HyMsg, Signature} from "../../src/interfaces/IHyperlane.sol";
import "forge-std/Test.sol";
import "forge-std/console2.sol";

abstract contract HyperlaneTestUtils is Test {
    uint256[] currentSigners;
    uint16 constant CHAIN_ID = 2; // Ethereum
    address hyperlaneAddr;

    function setUpHyperlane(uint8 numValidators, address[] memory initSigners) public returns (address) {
        if (initSigners.length == 0) {
            initSigners = new address[](numValidators);
        }
        Hyperlane hyperlane_ = new Hyperlane(initSigners);
        return address(hyperlane_);
    }

    function isNotMatch(bytes memory a, bytes memory b) public pure returns (bool) {
        return keccak256(a) != keccak256(b);
    }

    function generateUpdateData(
        uint32 nonce,
        uint64 timestamp,
        uint16 emitterChainId,
        bytes32 emitterAddress,
        bytes memory payload,
        uint8 numSigners
    ) public view returns (bytes memory updateData) {
        uint8 version = 1;

        bytes32[5] memory r = [
            bytes32(0x83db08d4e1590714aef8600f5f1e3c967ab6a3b9f93bb4242de0306510e688ea),
            bytes32(0xf81a5dd3f871ad2d27a3b538e73663d723f8263fb3d289514346d43d000175f5),
            bytes32(0x76b194f951f94492ca582dab63dc413b9ac1ca9992c22bc2186439e9ab8fdd3c),
            bytes32(0x35932eefd85897d868aaacd4ba7aee81a2384e42ba062133f6d37fdfebf94ad4),
            bytes32(0x6b38d4353d69396e91c57542254348d16459d448ab887574e9476a6ff76d49a1)
        ];

        bytes32[5] memory s = [
            bytes32(0x0af5d1d51ea7e51a291789ff4866a1e36bc4134d956870799380d2d71f5dbf3d),
            bytes32(0x083df770623e9ae52a7bb154473961e24664bb003bdfdba6100fb5e540875ce1),
            bytes32(0x62a6a6f402edaa53e9bdc715070a61edb0d98d4e14e182f60bdd4ae932b40b29),
            bytes32(0x78cce49db96ee27c3f461800388ac95101476605baa64a194b7dd4d56d2d4a4d),
            bytes32(0x3527627295bde423d7d799afef22affac4f00c70a5b651ad14c8879aeb9b6e03)
        ];

        bytes memory signatures;

        // Create signatures with provided data
        for (uint256 i = 0; i < numSigners; i++) {
            uint8 validatorIndex = uint8(i); // Example index for validator
            uint8 v = 27;
            // Pack all signature parts
            signatures = abi.encodePacked(signatures, validatorIndex, r[i], s[i], v);
        }

        // Create the body part of the data
        bytes memory body = abi.encodePacked(nonce, timestamp, emitterChainId, emitterAddress, payload);

        // Construct the updateData by concatenating all parts
        updateData =
            abi.encodePacked(version, numSigners, signatures, nonce, timestamp, emitterChainId, emitterAddress, payload);
    }
}

contract HyperlaneTestUtilsTest is Test, HyperlaneTestUtils {
    uint32 constant TEST_NONCE = 1234;
    uint64 constant TEST_UPDATE_TIMESTAMP = 112;
    uint16 constant TEST_EMITTER_CHAIN_ID = 7;
    bytes32 constant TEST_EMITTER_ADDR = 0x0000000000000000000000000000000000000000000000000000000000000bad;
    bytes constant TEST_PAYLOAD = hex"deadbeaf";
    uint8 constant TEST_NUM_SIGNERS = 5;

    function assertHyMsgMatchesTestValues(
        HyMsg memory hyMsg,
        bool valid,
        string memory reason,
        bytes memory updateData,
        IHyperlane hyperlane
    ) private view {
        assertTrue(valid);
        assertEq(reason, "");
        assertEq(hyMsg.nonce, TEST_NONCE);
        assertEq(hyMsg.timestamp, TEST_UPDATE_TIMESTAMP);
        assertEq(hyMsg.emitterChainId, TEST_EMITTER_CHAIN_ID);
        assertEq(hyMsg.emitterAddress, TEST_EMITTER_ADDR);
        assertEq(hyMsg.payload, TEST_PAYLOAD);
        // parseAndVerifyHyMsg() returns an empty signatures array for gas savings since it's not used
        // after its been verified. parseHyMsg() returns the full signatures array.
        (hyMsg, ) = hyperlane.parseHyMsg(updateData);
        assertEq(hyMsg.signatures.length, TEST_NUM_SIGNERS);
    }

    function testGenerateUpdateDataWorks() public {
        address[] memory validators = new address[](5);
        validators[0] = address(0x00df5d84a8877f990291daacbc5596d2fbc31a0335);
        validators[1] = address(0x00381ae5e8dd55310922fb238ac7564c7edc2269b3);
        validators[2] = address(0x0075579685c2dc4e12932e38472b4540616dc8ed95);
        validators[3] = address(0x00ed8df2d3a15d50f220f3d2bfeb263bf79d7a6c68);
        validators[4] = address(0x002791ba31fadd992776502d750ba2ba0e08f78f01);

        // Set up the Hyperlane contract with the provided validators
        IHyperlane hyperlane = IHyperlane(setUpHyperlane(uint8(validators.length), validators));

        bytes memory updateData = generateUpdateData(
            TEST_NONCE, TEST_UPDATE_TIMESTAMP, TEST_EMITTER_CHAIN_ID, TEST_EMITTER_ADDR, TEST_PAYLOAD, TEST_NUM_SIGNERS
        );

        (HyMsg memory hyMsg, bool valid, string memory reason,) = hyperlane.parseAndVerifyHyMsg(updateData);
        assertHyMsgMatchesTestValues(hyMsg, valid, reason, updateData, hyperlane);
    }

    function testParseHyMsg() public {
        // Create a sample encoded message
        bytes memory encodedHyMsg = abi.encodePacked(
            uint8(1), // version
            uint8(2), // number of signatures
            // First signature
            uint8(0), // validator index
            bytes32(uint256(1)), // r
            bytes32(uint256(2)), // s
            uint8(27), // v
            // Second signature
            uint8(1), // validator index
            bytes32(uint256(3)), // r
            bytes32(uint256(4)), // s
            uint8(28), // v
            // Rest of the message
            uint32(1234), // nonce
            uint64(block.timestamp), // timestamp
            uint16(5), // emitterChainId
            bytes32(uint256(6)), // emitterAddress
            bytes("Hello, Hyperlane!") // payload
        );

        address[] memory addresses;
        IHyperlane hyperlane = IHyperlane(setUpHyperlane(0, addresses));
        // Parse the message
       ( HyMsg memory parsedMsg,) = hyperlane.parseHyMsg(encodedHyMsg);

        // Verify parsed fields
        assertEq(parsedMsg.version, 1, "Incorrect version");
        assertEq(parsedMsg.signatures.length, 2, "Incorrect number of signatures");

        // Check first signature
        assertEq(parsedMsg.signatures[0].validatorIndex, 0, "Incorrect validator index for first signature");
        assertEq(uint256(parsedMsg.signatures[0].r), 1, "Incorrect r for first signature");
        assertEq(uint256(parsedMsg.signatures[0].s), 2, "Incorrect s for first signature");
        assertEq(parsedMsg.signatures[0].v, 27, "Incorrect v for first signature");

        // Check second signature
        assertEq(parsedMsg.signatures[1].validatorIndex, 1, "Incorrect validator index for second signature");
        assertEq(uint256(parsedMsg.signatures[1].r), 3, "Incorrect r for second signature");
        assertEq(uint256(parsedMsg.signatures[1].s), 4, "Incorrect s for second signature");
        assertEq(parsedMsg.signatures[1].v, 28, "Incorrect v for second signature");

        assertEq(parsedMsg.nonce, 1234, "Incorrect nonce");
        assertEq(parsedMsg.timestamp, block.timestamp, "Incorrect timestamp");
        assertEq(parsedMsg.emitterChainId, 5, "Incorrect emitter chain ID");
        assertEq(uint256(parsedMsg.emitterAddress), 6, "Incorrect emitter address");
        assertEq(parsedMsg.payload, bytes("Hello, Hyperlane!"), "Incorrect payload");

        // Verify hash
        bytes memory body = abi.encodePacked(
            uint32(1234), uint64(block.timestamp), uint16(5), bytes32(uint256(6)), bytes("Hello, Hyperlane!")
        );
        bytes32 expectedHash = keccak256(abi.encodePacked(keccak256(body)));
        assertEq(parsedMsg.hash, expectedHash, "Incorrect hash");
    }
}
