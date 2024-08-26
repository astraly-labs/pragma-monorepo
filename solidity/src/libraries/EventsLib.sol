// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title EventsLib
/// @author Pragma Labs
/// @custom:contact security@pragma.build
/// @notice Library exposing events.
library EventsLib {
    /// @dev Emitted when the data feed with `feedId` has received a fresh update.
    /// @param feedId Pragma Feed ID.
    /// @param publishTime Unix timestamp of the update.
    /// @param value New value of the data feed.
    event DataFeedUpdate(
        bytes32 indexed feedId,
        uint64 publishTime,
        uint32 numSourcesAggregated,
        int64 value
    );
}