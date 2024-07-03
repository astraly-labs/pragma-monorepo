// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

struct DataFeed {
    bytes dataId;
    uint64 timestamp;
    uint32 numSourcesAggregated;
    bytes data;
}

/// @title IPragma
/// @author Pragma Labs
/// @custom:contact security@pragma.build
interface IPragma {
    /// @notice Updates data in the Pragma contract.
    /// @param dataId The data id.
    /// @param data The data.
    function updateData(bytes calldata dataId, bytes calldata data) external;

    /// @notice Gets data from the Pragma contract.
    /// @param dataId The data id.
    /// @return The data.
    /// @dev Data is returned as bytes,
    function getData(
        bytes calldata dataId
    ) external view returns (bytes memory);
}
