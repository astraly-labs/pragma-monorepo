// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "./PragmaStructs.sol";

/// @title IPragma
/// @author Pragma Labs
/// @custom:contact security@pragma.build
interface IPragma {
    /// @notice Updates data feeds given some update data.
    /// Before calling this function, the caller must have paid the required fee.
    /// Which can be calculated using the `getUpdateFee` function.
    /// Data feeds will only be updated if data is more recent than the current data.
    /// @dev Emits a `DataFeedUpdate` event for each updated data feed.
    /// @dev Reverts if the caller has not paid the required fee.
    /// @param updateData The data.
    function updateDataFeeds(bytes[] calldata updateData) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint256 feeAmount);
    /// @notice Fetches the latest spot median price that is no older than a specified age.
    /// @param id The unique identifier of the data feed.
    /// @param age The maximum allowed age (in seconds) for the price data.
    /// @return The latest valid SpotMedian data, or a revert if no valid data is available within the specified age.
    function getSpotMedianNoOlderThan(bytes32 id, uint256 age) external view returns (SpotMedian memory);

    /// @notice Fetches the latest TWAP (Time-Weighted Average Price) that is no older than a specified age.
    /// @param id The unique identifier of the TWAP data feed.
    /// @param age The maximum allowed age (in seconds) for the TWAP data.
    /// @return The latest valid TWAP data, or a revert if no valid data is available within the specified age.
    function getTwapNoOlderThan(bytes32 id, uint256 age) external view returns (TWAP memory);

    /// @notice Fetches the latest realized volatility that is no older than a specified age.
    /// @param id The unique identifier of the realized volatility data feed.
    /// @param age The maximum allowed age (in seconds) for the volatility data.
    /// @return The latest valid RealizedVolatility data, or a revert if no valid data is available within the specified age.
    function getRealizedVolatilityNoOlderThan(bytes32 id, uint256 age)
        external
        view
        returns (RealizedVolatility memory);

    /// @notice Fetches the latest options data that is no older than a specified age.
    /// @param id The unique identifier of the options data feed.
    /// @param age The maximum allowed age (in seconds) for the options data.
    /// @return The latest valid Options data, or a revert if no valid data is available within the specified age.
    function getOptionsNoOlderThan(bytes32 id, uint256 age) external view returns (Options memory);

    /// @notice Fetches the latest perpetuals data that is no older than a specified age.
    /// @param id The unique identifier of the perpetuals data feed.
    /// @param age The maximum allowed age (in seconds) for the perpetuals data.
    /// @return The latest valid Perp data, or a revert if no valid data is available within the specified age.
    function getPerpNoOlderThan(bytes32 id, uint256 age) external view returns (Perp memory);

    /// @notice Checks if a data feed exists.
    /// @param id The data feed ID.
    /// @return True if the data feed exists, false otherwise.
    function dataFeedExists(bytes32 id) external view returns (bool);

    /// @notice Getter accesssible through the interface
    /// @param feedId The data feed id.
    /// @return SpotMedian the entry associated to the spot feed id.
    function getSpotMedianFeed(bytes32 feedId) external view returns (SpotMedian memory);
}
