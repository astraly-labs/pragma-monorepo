// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
    uint8 validatorIndex;
}

struct HyMsg {
    uint8 version;
    uint32 timestamp;
    uint32 nonce;
    uint16 emitterChainId;
    bytes32 emitterAddress;
    bytes payload;
    Signature[] signatures;
    bytes32 hash;
}

/// @title IHyperlane
/// @author Pragma Labs
/// @custom:contact security@pragma.build
interface IHyperlane {
    /// @notice Parses and verifies a Hyperlane message.
    /// @dev message should be encoded following the specs (TODO: add docs)
    /// @param encodedHyMsg The encoded Hyperlane message.
    /// @return hyMsg The parsed Hyperlane message.
    /// @return valid Whether the message is valid.
    /// @return reason The reason the message is invalid.
    function parseAndVerifyHyMsg(
        bytes calldata encodedHyMsg
    ) external view returns (HyMsg memory hyMsg, bool valid, string memory reason);
}