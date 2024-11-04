// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IHyperlane} from "./interfaces/IHyperlane.sol";
import "./interfaces/PragmaStructs.sol";
import "./libraries/BytesLib.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @title Hyperlane Contract
/// @notice This contract verifies and parses messages signed by validators.
/// @dev The contract uses validator signatures to reach a quorum and validate the authenticity of messages.
/// Validators are initialized during contract deployment and stored in `_validators`.
contract Hyperlane is IHyperlane {
    using BytesLib for bytes;
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /* STORAGE */

    address[] public _validators;
    uint256 private constant VERSION = 3;

    /* CONSTRUCTOR */

    /// @notice Initializes the contract with a list of validators.
    /// @param validators Array of validator addresses authorized to sign messages.
    constructor(address[] memory validators) {
        _validators = validators;
    }

    /// @notice Parses and verifies a Hyperlane message.
    /// @param encodedHyMsg The encoded Hyperlane message.
    /// @return hyMsg The parsed Hyperlane message.
    /// @return valid Boolean indicating if the message is valid.
    /// @return reason Reason for invalidity, if applicable.
    /// @return index The message parsing index for tracking.
    /// @return checkpointRoot The checkpoint root associated with the message.
    function parseAndVerifyHyMsg(bytes calldata encodedHyMsg)
        public
        view
        returns (HyMsg memory hyMsg, bool valid, string memory reason, uint256 index, bytes32 checkpointRoot)
    {
        (hyMsg, index, checkpointRoot) = parseHyMsg(encodedHyMsg);
        (valid, reason) = verifyHyMsg(hyMsg);
    }

    /// @notice Verifies a parsed Hyperlane message by checking the quorum of validator signatures.
    /// @param hyMsg The parsed Hyperlane message.
    /// @return valid Boolean indicating if the message is valid.
    /// @return reason Reason for invalidity, if applicable.
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

    /// @notice Verifies the signatures of validators on the message.
    /// @param hash The message hash to verify.
    /// @param signatures Array of validator signatures on the message.
    /// @param validators List of validator addresses.
    /// @return valid Boolean indicating if signatures are valid.
    /// @return reason Reason for invalidity, if applicable.
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

    /// @notice Parses a Hyperlane message from encoded data, and compute the hash to be signed by the validators.
    /// @param encodedHyMsg The encoded Hyperlane message data.
    /// @return hyMsg The parsed Hyperlane message.
    /// @return index The index in the data stream, for further parsing.
    /// @return checkPointRoot The checkpoint root associated with the message.
    function parseHyMsg(bytes calldata encodedHyMsg)
        public
        pure
        returns (HyMsg memory hyMsg, uint256 index, bytes32 checkPointRoot)
    {
        hyMsg.version = encodedHyMsg.toUint8(index);
        index += 1;
        require(hyMsg.version == VERSION, "unsupported version");

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

        hyMsg.emitterChainId = encodedHyMsg.toUint32(index);
        index += 4;

        hyMsg.emitterAddress = encodedHyMsg.toBytes32(index);
        index += 32;

        bytes32 merkleTreeHookAddress = encodedHyMsg.toBytes32(index);
        index += 32;

        bytes32 domainHash = keccak256(abi.encodePacked(hyMsg.emitterChainId, merkleTreeHookAddress, "HYPERLANE"));

        bytes32 root = encodedHyMsg.toBytes32(index);
        index += 32;

        checkPointRoot = root;

        uint32 checkpointIndex = encodedHyMsg.toUint32(index);
        index += 4;

        bytes32 messageId = encodedHyMsg.toBytes32(index);
        index += 32;

        // Hash the configuration
        hyMsg.hash = keccak256(abi.encodePacked(domainHash, root, checkpointIndex, messageId));

        hyMsg.payload = encodedHyMsg.slice(index, encodedHyMsg.length - index);
    }

    /// @notice Verifies a single signature against an account.
    /// @param data The hashed data to verify.
    /// @param signature The signature to verify.
    /// @param account The address expected to sign the data.
    /// @return Boolean indicating whether the signature is valid.
    function _verify(bytes32 data, bytes memory signature, address account) internal pure returns (bool) {
        return data.toEthSignedMessageHash().recover(signature) == account;
    }
}
