// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import {IPragma, DataFeed} from "./interfaces/IPragma.sol";
import "./PragmaDecoder.sol";
import "./libraries/EventsLib.sol";
import "./libraries/ErrorsLib.sol";
import "./interfaces/PragmaStructs.sol";
import "./libraries/DataParser.sol";

/// @title Pragma
/// @author Pragma Labs
/// @custom:contact security@pragma.build
/// @notice The Pragma contract.
contract Pragma is IPragma, PragmaDecoder {
    /* STORAGE */
    uint256 public validTimePeriodSeconds;
    uint256 public singleUpdateFeeInWei;

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

    function getSpotMedianNoOlderThan(bytes32 id, uint256 age) external view returns (SpotMedian memory data) {
        data = spotMedianFeeds[id];
        if (data.metadata.timestamp == 0) {
            revert ErrorsLib.DataNotFound();
        }
        if (diff(block.timestamp, data.metadata.timestamp) > age) {
            revert ErrorsLib.DataStale();
        }
        return data;
    }

    function getTwapNoOlderThan(bytes32 id, uint256 age) external view returns (TWAP memory data) {
        data = twapFeeds[id];
        if (data.metadata.timestamp == 0) {
            revert ErrorsLib.DataNotFound();
        }
        if (diff(block.timestamp, data.metadata.timestamp) > age) {
            revert ErrorsLib.DataStale();
        }
    }

    function getRealizedVolatilityNoOlderThan(bytes32 id, uint256 age)
        external
        view
        returns (RealizedVolatility memory data)
    {
        data = rvFeeds[id];
        if (data.metadata.timestamp == 0) {
            revert ErrorsLib.DataNotFound();
        }
        if (diff(block.timestamp, data.metadata.timestamp) > age) {
            revert ErrorsLib.DataStale();
        }
    }

    function getOptionsNoOlderThan(bytes32 id, uint256 age) external view returns (Options memory data) {
        data = optionsFeeds[id];
        if (data.metadata.timestamp == 0) {
            revert ErrorsLib.DataNotFound();
        }
        if (diff(block.timestamp, data.metadata.timestamp) > age) {
            revert ErrorsLib.DataStale();
        }
    }

    function getPerpNoOlderThan(bytes32 id, uint256 age) external view returns (Perp memory data) {
        data = perpFeeds[id];
        if (data.metadata.timestamp == 0) {
            revert ErrorsLib.DataNotFound();
        }
        if (diff(block.timestamp, data.metadata.timestamp) > age) {
            revert ErrorsLib.DataStale();
        }
    }

    /// @inheritdoc IPragma
    function dataFeedExists(bytes32 id) external view returns (bool) {
       FeedType feedType = DataParser.safeCastToFeedType(uint8(id[0]));
       if (feedType == FeedType.SpotMedian) {
            return(spotMedianFeeds[id].metadata.timestamp !=0);
        } else if (feedType == FeedType.Twap) {
            return(twapFeeds[id].metadata.timestamp !=0);
        } else if (feedType == FeedType.RealizedVolatility) {
           return(rvFeeds[id].metadata.timestamp !=0);
        } else if (feedType == FeedType.Options) {
           return(optionsFeeds[id].metadata.timestamp !=0);
        } else if (feedType == FeedType.Perpetuals) {
            return(perpFeeds[id].metadata.timestamp !=0);
        } else {
            revert ErrorsLib.InvalidDataFeedType();
        }
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
