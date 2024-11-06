// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./DataParser.sol"; // Import DataParser to use the structs

/// @title EventsLib
/// @author Pragma Labs
/// @custom:contact security@pragma.build
/// @notice Library exposing events for various data feed updates.
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

    /// @dev Emitted when a Spot Median feed with `feedId` has received a fresh update.
    /// @param feedId Pragma Feed ID.
    /// @param publishTime Unix timestamp of the update.
    /// @param spotMedian New Spot Median data.
    event SpotMedianUpdate(
        bytes32 indexed feedId,
        uint64 publishTime,
        SpotMedian spotMedian
    );

    /// @dev Emitted when a TWAP feed with `feedId` has received a fresh update.
    /// @param feedId Pragma Feed ID.
    /// @param publishTime Unix timestamp of the update.
    /// @param twap New TWAP data.
    event TWAPUpdate(bytes32 indexed feedId, uint64 publishTime, TWAP twap);

    /// @dev Emitted when a Realized Volatility feed with `feedId` has received a fresh update.
    /// @param feedId Pragma Feed ID.
    /// @param publishTime Unix timestamp of the update.
    /// @param realizedVolatility New Realized Volatility data.
    event RealizedVolatilityUpdate(
        bytes32 indexed feedId,
        uint64 publishTime,
        RealizedVolatility realizedVolatility
    );

    /// @dev Emitted when an Options feed with `feedId` has received a fresh update.
    /// @param feedId Pragma Feed ID.
    /// @param publishTime Unix timestamp of the update.
    /// @param options New Options data.
    event OptionsUpdate(
        bytes32 indexed feedId,
        uint64 publishTime,
        Options options
    );

    /// @dev Emitted when a Perp feed with `feedId` has received a fresh update.
    /// @param feedId Pragma Feed ID.
    /// @param publishTime Unix timestamp of the update.
    /// @param perp New Perp data.
    event PerpUpdate(bytes32 indexed feedId, uint64 publishTime, Perp perp);
}
