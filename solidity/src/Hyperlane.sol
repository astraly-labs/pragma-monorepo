// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {HyMsg, Signature} from "./interfaces/IHyperlane.sol";
import "./libraries/BytesLib.sol";

contract Hyperlane {
    using BytesLib for bytes;

    address[] public _validators;

    function parseAndVerifyHyMsg(
        bytes calldata encodedHyMsg
    ) public view returns (HyMsg memory hyMsg, bool valid, string memory reason) {
        hyMsg = parseHyMsg(encodedHyMsg);
        (valid, reason) = verifyHyMsg(hyMsg);
    }

    function verifyHyMsg(HyMsg memory hyMsg) public view returns (bool valid, string memory reason) {
        // TODO: fetch validators from calldata/storage
        address[] memory validators = _validators;
        
        if (validators.length == 0) {
            return (false, "no validators announced");
        }

        // We're using a fixed point number transformation with 1 decimal to deal with rounding.
        if (
            (((validators.length * 10) / 3) * 2) / 10 + 1 >
            hyMsg.signatures.length
        ) {
            return (false, "no quorum");
        }

        // Verify signatures
        (bool signaturesValid, string memory invalidReason) = verifySignatures(
            hyMsg.hash,
            hyMsg.signatures,
            validators
        );
        if (!signaturesValid) {
            return (false, invalidReason);
        }

        return (true, "");
    }

    function verifySignatures(
        bytes32 hash,
        Signature[] memory signatures,
        address[] memory validators
    ) public pure returns (bool valid, string memory reason) {
        uint8 lastIndex = 0;
        for (uint i = 0; i < signatures.length; i++) {
            Signature memory sig = signatures[i];

            require(
                i == 0 || sig.validatorIndex > lastIndex,
                "signature indices must be ascending"
            );
            lastIndex = sig.validatorIndex;

            if (
                ecrecover(hash, sig.v, sig.r, sig.s) !=
                validators[sig.validatorIndex]
            ) {
                return (false, "HyMsg signature invalid");
            }
        }
        return (true, "");
    }

    function parseHyMsg(bytes calldata encodedHyMsg) public pure returns (HyMsg memory hyMsg) {
        uint index = 0;

        hyMsg.version = encodedHyMsg.toUint8(index);
        index += 1;
        require(hyMsg.version == 1, "unsupported version");

        // Parse Signatures
        uint256 signersLen = encodedHyMsg.toUint8(index);
        index += 1;
        hyMsg.signatures = new Signature[](signersLen);

        for (uint i = 0; i < signersLen; i++) {
            hyMsg.signatures[i].validatorIndex = encodedHyMsg.toUint8(index);
            index += 1;

            hyMsg.signatures[i].r = encodedHyMsg.toBytes32(index);
            index += 32;
            hyMsg.signatures[i].s = encodedHyMsg.toBytes32(index);
            index += 32;
            hyMsg.signatures[i].v = encodedHyMsg.toUint8(index) + 27;
            index += 1;
        }

        // Hash the body
        bytes memory body = encodedHyMsg.slice(index, encodedHyMsg.length - index);
        hyMsg.hash = keccak256(abi.encodePacked(keccak256(body)));

        // Parse the rest of the message
        hyMsg.nonce = encodedHyMsg.toUint32(index);
        index += 4;

        hyMsg.emitterChainId = encodedHyMsg.toUint16(index);
        index += 2;

        hyMsg.emitterAddress = encodedHyMsg.toBytes32(index);
        index += 32;

        hyMsg.payload = encodedHyMsg.slice(index, encodedHyMsg.length - index);
    }
}