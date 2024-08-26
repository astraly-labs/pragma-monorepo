// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import { IPragma, DataFeed } from "./interfaces/IPragma.sol";

/// @title Pragma
/// @author Pragma Labs
/// @custom:contact security@pragma.build
/// @notice The Pragma contract.
contract Pragma is IPragma {

    /* STORAGE */

    address payable public hyperlane;
    uint16[] public dataSourceEmitterChainIds;
    bytes32[] public dataSourceEmitterAddresses;
    uint public validTimePeriodSeconds;
    uint public singleUpdateFeeInWei;
    mapping(bytes32 => uint64) public latestDataInfoPublishTime;

    constructor(
        address _hyperlane,
        uint16[] memory _dataSourceEmitterChainIds,
        bytes32[] memory _dataSourceEmitterAddresses,
        uint _validTimePeriodSeconds,
        uint _singleUpdateFeeInWei
    ) {
        // Initialize the contract.
        hyperlane = payable(_hyperlane);
        dataSourceEmitterChainIds = _dataSourceEmitterChainIds;
        dataSourceEmitterAddresses = _dataSourceEmitterAddresses;
        validTimePeriodSeconds = _validTimePeriodSeconds;
        singleUpdateFeeInWei = _singleUpdateFeeInWei;
    }

    /// @inheritdoc IPragma
    function updateDataFeeds(
        bytes[] calldata updateData
    ) external payable {
        // Update the data feeds.
    }

    /// @inheritdoc IPragma
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount) {
        // Get the update fee.
    }

    function getTotalFee(
        uint totalNumUpdates
    ) private view returns (uint requiredFee) {
        return totalNumUpdates * singleUpdateFeeInWei;
    }

    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (DataFeed memory data) {
        // Get the price no older than.
    }

    /// @inheritdoc IPragma
    function dataFeedExists(bytes32 id) external view returns (bool) {
        return (latestDataInfoPublishTime[id] != 0);
    }

    function getValidTimePeriod() public view returns (uint) {
        return validTimePeriodSeconds;
    }

    function version() public pure returns (string memory) {
        return "1.0.0";
    }
}
