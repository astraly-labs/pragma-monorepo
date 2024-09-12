// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;


import "./structs.sol";

/// @title IHyperlane
/// @author Pragma Labs
/// @custom:contact security@pragma.build
interface IHyperlane {
    /// @notice Parses and verifies the signature of an Hyperlane message.
    /// @dev message should be encoded following the specs (TODO: add docs)
    /// @param encodedHyMsg The encoded Hyperlane message.
    /// @return hyMsg The parsed Hyperlane message.
    /// @return valid Whether the message is valid.
    /// @return reason The reason the message is invalid.
    function parseAndVerifyHyMsg(bytes calldata encodedHyMsg)
        external
        view
        returns (HyMsg memory hyMsg, bool valid, string memory reason, uint256 index);

    /// @notice Parses an Hyperlane message.
    /// @dev message should be encoded following the specs (TODO: add docs)
    /// @param encodedHyMsg The encoded Hyperlane message.
    /// @return hyMsg The parsed Hyperlane message.
    function parseHyMsg(bytes calldata encodedHyMsg) external pure returns (HyMsg memory hyMsg, uint256 index);
}
