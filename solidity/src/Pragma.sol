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
/// @dev This contract uses the UUPS (Universal Upgradeable Proxy Standard) pattern for upgradability.
/// It inherits functionality from OwnableUpgradeable for access control,
/// and includes custom libraries for data parsing and validation
/// @custom:contact security@pragma.build
/// @notice The Pragma contract.
contract Pragma is Initializable, UUPSUpgradeable, OwnableUpgradeable, IPragma, PragmaDecoder {
    /* STORAGE */

    /// @notice The period, in seconds, for which data is considered valid (default 60s)
    uint256 public validTimePeriodSeconds;

    /// @notice The fee in wei required for a single update.
    uint256 public singleUpdateFeeInWei;

    /* CONSTRUCTOR */

    constructor() {
        _disableInitializers();
    }

    /* INITIALIZER */

    /// @notice Initializes the contract with initial parameters.
    /// @param _hyperlane Address of the Hyperlane contract deployed on the chain.
    /// @param initial_owner Address of the owner of the contract.
    /// @param _dataSourceEmitterChainIds Registry of valid chain IDs for data source emitters.
    /// @param _dataSourceEmitterAddresses Registry of valid data source emitters addresses for their respective chains.
    /// @param _validTimePeriodSeconds Maximum period in seconds a data feed is valid.
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

    /// @notice Authorizes the contract upgrade to a new implementation address.
    /// @param newImplementation Address of the new implementation contract.
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
        if (msg.value < requiredFee) revert ErrorsLib.InsufficientFee();
    }

    /// @inheritdoc IPragma
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint256 feeAmount) {
        return 0;
    }

    /// @notice Calculates the total fee required for a specified number of updates.
    /// @param totalNumUpdates Number of updates to process.
    /// @return requiredFee The calculated fee.
    function getTotalFee(uint256 totalNumUpdates) private view returns (uint256 requiredFee) {
        return totalNumUpdates * singleUpdateFeeInWei;
    }

    /// @inheritdoc IPragma
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

    /// @inheritdoc IPragma
    function getTwapNoOlderThan(bytes32 id, uint256 age) external view returns (TWAP memory data) {
        data = twapFeeds[id];
        if (data.metadata.timestamp == 0) {
            revert ErrorsLib.DataNotFound();
        }
        if (diff(block.timestamp, data.metadata.timestamp) > age) {
            revert ErrorsLib.DataStale();
        }
    }

    /// @inheritdoc IPragma
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

    /// @inheritdoc IPragma
    function getOptionsNoOlderThan(bytes32 id, uint256 age) external view returns (Options memory data) {
        data = optionsFeeds[id];
        if (data.metadata.timestamp == 0) {
            revert ErrorsLib.DataNotFound();
        }
        if (diff(block.timestamp, data.metadata.timestamp) > age) {
            revert ErrorsLib.DataStale();
        }
    }

    /// @inheritdoc IPragma
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

    /// @notice Retrieves the valid time period for data in seconds.
    /// @return validTimePeriodSeconds The configured time period.
    function getValidTimePeriod() public view returns (uint256) {
        return validTimePeriodSeconds;
    }

    /// @notice Allows the owner to withdraw the specified amount from the contract.
    /// @param amount The amount in wei to withdraw.
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
