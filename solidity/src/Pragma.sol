// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import {IPragma, DataFeed} from "./interfaces/IPragma.sol";
import "./PragmaDecoder.sol";
import "./libraries/EventsLib.sol";
import "./libraries/ErrorsLib.sol";

/// @title Pragma
/// @author Pragma Labs
/// @custom:contact security@pragma.build
/// @notice The Pragma contract.
contract Pragma is IPragma, PragmaDecoder {
    /* STORAGE */
    uint256 public validTimePeriodSeconds;
    uint256 public singleUpdateFeeInWei;
    mapping(bytes32 => uint64) public latestDataInfoPublishTime;

    constructor(
        address _hyperlane,
        uint16[] memory _dataSourceEmitterChainIds,
        bytes32[] memory _dataSourceEmitterAddresses,
        uint256 _validTimePeriodSeconds,
        uint256 _singleUpdateFeeInWei
    ) PragmaDecoder(_hyperlane, _dataSourceEmitterChainIds, _dataSourceEmitterAddresses) {
        validTimePeriodSeconds = _validTimePeriodSeconds;
        singleUpdateFeeInWei = _singleUpdateFeeInWei;
    }

    /// @inheritdoc IPragma
    function updateDataFeeds(bytes[] calldata updateData) external payable {
        uint256 totalNumUpdates = 0;
        uint256 len = updateData.length;
        for (uint256 i = 0; i < len;) {
            totalNumUpdates += updateDataInfoFromUpdate(updateData[i]);
            unchecked {
                i++;
            }
        }
        uint256 requiredFee = getTotalFee(totalNumUpdates);
        if (msg.value < requiredFee) {
            revert ErrorsLib.InsufficientFee();
        }
    }

    /// @inheritdoc IPragma
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint256 feeAmount) {
        // Get the update fee.
    }

    function getTotalFee(uint256 totalNumUpdates) private view returns (uint256 requiredFee) {
        return totalNumUpdates * singleUpdateFeeInWei;
    }

    function getPriceUnsafe(bytes32 id) private view returns (DataFeed memory) {
        DataFeed memory data = _latestPriceInfo[id];
        if (data.publishTime == 0) {
            revert ErrorsLib.DataNotFound();
        }
        return data;
    }

    function getPriceNoOlderThan(bytes32 id, uint256 age) external view returns (DataFeed memory data) {
        data = getPriceUnsafe(id);

        if (diff(block.timestamp, data.publishTime) > age) {
            revert ErrorsLib.DataStale();
        }
    }

    /// @inheritdoc IPragma
    function dataFeedExists(bytes32 id) external view returns (bool) {
        return (latestDataInfoPublishTime[id] != 0);
    }

    function getValidTimePeriod() public view returns (uint256) {
        return validTimePeriodSeconds;
    }

    function version() public pure returns (string memory) {
        return "1.0.0";
    }

    function diff(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x > y) {
            return x - y;
        } else {
            return y - x;
        }
    }
}
