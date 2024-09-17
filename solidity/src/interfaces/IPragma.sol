// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

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

    function getSpotMedianNoOlderThan(bytes32 id, uint256 age) external view returns (SpotMedian memory);


    function getTwapNoOlderThan(bytes32 id, uint256 age) external view returns (TWAP memory );


    function getRealizedVolatilityNoOlderThan(bytes32 id, uint256 age) external view returns (RealizedVolatility memory );

    
    function getOptionsNoOlderThan(bytes32 id, uint256 age) external view returns (Options memory);

    function getPerpNoOlderThan(bytes32 id, uint256 age) external view returns (Perp memory);

    /// @notice Checks if a data feed exists.
    /// @param id The data feed ID.
    /// @return True if the data feed exists, false otherwise.
    function dataFeedExists(bytes32 id) external view returns (bool);
}
