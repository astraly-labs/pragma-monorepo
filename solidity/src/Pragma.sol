// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {IPragma, DataFeed} from "./interfaces/IPragma.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./PragmaDecoder.sol";
import "./libraries/EventsLib.sol";
import "./libraries/ErrorsLib.sol";
import "./interfaces/PragmaStructs.sol";
import "./libraries/DataParser.sol";

/// @title Pragma
/// @author Pragma Labs
/// @custom:contact security@pragma.build
/// @notice The Pragma contract.
contract Pragma is Initializable, UUPSUpgradeable, OwnableUpgradeable, IPragma, PragmaDecoder {
    /* STORAGE */
    uint256 public validTimePeriodSeconds;
    uint256 public singleUpdateFeeInWei;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _hyperlane,
        address initial_owner,
        uint32[] memory _dataSourceEmitterChainIds,
        bytes32[] memory _dataSourceEmitterAddresses,
        uint256 _validTimePeriodSeconds,
        uint256 _singleUpdateFeeInWei
    ) public initializer {
        __Ownable_init(initial_owner);
        __UUPSUpgradeable_init();
        hyperlane = IHyperlane(_hyperlane);

        for (uint256 i = 0; i < _dataSourceEmitterChainIds.length; i++) {
            _isValidDataSource[keccak256(
                abi.encodePacked(_dataSourceEmitterChainIds[i], _dataSourceEmitterAddresses[i])
            )] = true;
        }
        validTimePeriodSeconds = _validTimePeriodSeconds;
        singleUpdateFeeInWei = _singleUpdateFeeInWei;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

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
        return 0;
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
            return (spotMedianFeeds[id].metadata.timestamp != 0);
        } else if (feedType == FeedType.Twap) {
            return (twapFeeds[id].metadata.timestamp != 0);
        } else if (feedType == FeedType.RealizedVolatility) {
            return (rvFeeds[id].metadata.timestamp != 0);
        } else if (feedType == FeedType.Options) {
            return (optionsFeeds[id].metadata.timestamp != 0);
        } else if (feedType == FeedType.Perpetuals) {
            return (perpFeeds[id].metadata.timestamp != 0);
        } else {
            revert ErrorsLib.InvalidDataFeedType();
        }
    }

    function getValidTimePeriod() public view returns (uint256) {
        return validTimePeriodSeconds;
    }

    /* GETTERS */
    /// Even if the getters are automatically set for the public storage variable, we need to define the getter to make it
    /// accessible for the interface

    function getSpotMedianFeed(bytes32 feedId) external view returns (SpotMedian memory) {
        return spotMedianFeeds[feedId];
    }

    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        (bool success,) = owner().call{value: amount}("");
        require(success, "Transfer failed");
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
