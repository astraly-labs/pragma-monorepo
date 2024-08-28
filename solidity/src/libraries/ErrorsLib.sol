// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title ErrorsLib
/// @author Pragma Labs
/// @custom:contact security@pragma.build
/// @notice Library exposing errors.
library ErrorsLib {
    // Insufficient fee is paid to the method.
    // Signature: 0x025dbdd4
    error InsufficientFee();
    // Update data is coming from an invalid data source.
    // Signature: 0xe60dce71
    error InvalidUpdateDataSource();
    // Version is invalid.
    // TODO: add signature
    error InvalidVersion();
    // Given message is not a valid Hyperlane Checkpoint Root.
    // TODO: add signature
    error InvalidHyperlaneCheckpointRoot();
    // Update data is invalid (e.g., deserialization error)
    // Signature: 0xe69ffece
    error InvalidUpdateData();
    // Data feed type is not supported.
    // TODO: add signature
    error InvalidDataFeedType();
}