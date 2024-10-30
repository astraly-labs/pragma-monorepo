// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IHyperlane} from "./interfaces/IHyperlane.sol";
import "./interfaces/PragmaStructs.sol";
import "./libraries/BytesLib.sol";
import "forge-std/console2.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract Hyperlane is IHyperlane {
    using BytesLib for bytes;

    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address[] public _validators;

    constructor(address[] memory validators) {
        _validators = validators;
    }

    function parseAndVerifyHyMsg(bytes calldata encodedHyMsg)
        public
        view
        returns (HyMsg memory hyMsg, bool valid, string memory reason, uint256 index, bytes32 checkpointRoot)
    {
        (hyMsg, index, checkpointRoot) = parseHyMsg(encodedHyMsg);
        (valid, reason) = verifyHyMsg(hyMsg);
    }

    function verifyHyMsg(HyMsg memory hyMsg) public view returns (bool valid, string memory reason) {
        // TODO: fetch validators from calldata/storage
        address[] memory validators = _validators;
        if (validators.length == 0) {
            return (false, "no validators announced");
        }

        // We're using a fixed point number transformation with 1 decimal to deal with rounding.
        // we check that we have will be able to reach a quorum with the current signatures
        if ((((validators.length * 10) / 3) * 2) / 10 + 1 > hyMsg.signatures.length) {
            return (false, "no quorum");
        }
        // Verify signatures
        (bool signaturesValid, string memory invalidReason) = verifySignatures(hyMsg.hash, hyMsg.signatures, validators);
        if (!signaturesValid) {
            return (false, invalidReason);
        }

        return (true, "");
    }

    function verifySignatures(bytes32 hash, Signature[] memory signatures, address[] memory validators)
        public
        pure
        returns (bool valid, string memory reason)
    {
        uint8 lastIndex = 0;
        // TODO: break on quorum
        for (uint256 i = 0; i < signatures.length; i++) {
            Signature memory sig = signatures[i];

            require(i == 0 || sig.validatorIndex > lastIndex, "signature indices must be ascending");
            lastIndex = sig.validatorIndex;
            bytes memory signature = abi.encodePacked(sig.r, sig.s, sig.v);
            if (!_verify(hash, signature, validators[sig.validatorIndex])) {
                return (false, "HyMsg signature invalid");
            }
        }
        return (true, "");
    }

    function parseHyMsg(bytes calldata encodedHyMsg)
        public
        pure
        returns (HyMsg memory hyMsg, uint256 index, bytes32 checkPointRoot)
    {
        hyMsg.version = encodedHyMsg.toUint8(index);
        index += 1;
        require(hyMsg.version == 3, "unsupported version");

        // Parse Signatures
        uint256 signersLen = encodedHyMsg.toUint8(index);
        index += 1;
        hyMsg.signatures = new Signature[](signersLen);
        for (uint256 i = 0; i < signersLen; i++) {
            hyMsg.signatures[i].validatorIndex = encodedHyMsg.toUint8(index);
            index += 1;

            hyMsg.signatures[i].r = encodedHyMsg.toBytes32(index);

            index += 32;
            hyMsg.signatures[i].s = encodedHyMsg.toBytes32(index);
            index += 32;
            hyMsg.signatures[i].v = encodedHyMsg.toUint8(index);
            index += 1;
        }

        // Parse the rest of the message
        hyMsg.nonce = encodedHyMsg.toUint32(index);
        index += 4;

        hyMsg.timestamp = encodedHyMsg.toUint64(index);
        index += 8;

        hyMsg.emitterChainId = encodedHyMsg.toUint32(index);
        index += 4;

        hyMsg.emitterAddress = encodedHyMsg.toBytes32(index);
        index += 32;

        bytes32 merkeTreeHookAddress = encodedHyMsg.toBytes32(index);
        index += 32;

        bytes32 domainHash = keccak256(abi.encodePacked(hyMsg.emitterChainId, merkeTreeHookAddress, "HYPERLANE"));

        bytes32 root = encodedHyMsg.toBytes32(index);
        checkPointRoot = root;
        index += 32;

        uint32 checkpointIndex = encodedHyMsg.toUint32(index);
        index += 4;

        bytes32 messageId = encodedHyMsg.toBytes32(index);
        index += 32;

        // Hash the configuration
        hyMsg.hash = keccak256(abi.encodePacked(domainHash, root, checkpointIndex, messageId));

        hyMsg.payload = encodedHyMsg.slice(index, encodedHyMsg.length - index);
    }

    function _verify(bytes32 data, bytes memory signature, address account) internal pure returns (bool) {
        return data.toEthSignedMessageHash().recover(signature) == account;
    }
}
