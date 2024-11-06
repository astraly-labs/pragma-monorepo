pragma solidity 0.8.28;

// Replace this import with those down below once PR merged

import "../interfaces/PragmaStructs.sol";
import "../interfaces/IPragma.sol";
import "../libraries/ErrorsLib.sol";

// import "@pragmaoracle/solidity-sdk/src/interfaces/IPragma.sol";
// import "@pragmaoracle/solidity-sdk/src/interfaces/PragmaStructs.sol";

/**
 * @title An adapter of the Pyth interface that supports Pragma price feeds
 * Users should deploy an instance of this contract to wrap every price feed id that they need to use.
 */

contract PragmaAggregatorV3 {
    IPragma public immutable pragmaInterface;

    constructor(address _pragma) {
        pragmaInterface = IPragma(_pragma);
    }

    function getPriceUnsafe(
        bytes32 id
    ) public view returns (SpotMedian memory) {
        SpotMedian memory feed = pragmaInterface.getSpotMedianFeed(id);
        return feed;
    }

    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) public view returns (SpotMedian memory) {
        SpotMedian memory feed = getPriceUnsafe(id);

        if (diff(block.timestamp, feed.metadata.timestamp) > age)
            revert ErrorsLib.DataStale();

        return feed;
    }

    function updatePriceFeeds(bytes[] calldata updateData) public payable {
        pragmaInterface.updateDataFeeds(updateData);
    }

    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount) {
        return pragmaInterface.getUpdateFee(updateData);
    }

    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata feedIds,
        uint64[] calldata publishTimes
    ) external payable {
        if (feedIds.length != publishTimes.length)
            revert ErrorsLib.InvalidArgument();

        for (uint i = 0; i < feedIds.length; i++) {
            if (
                !pragmaInterface.dataFeedExists(feedIds[i]) ||
                pragmaInterface
                    .getSpotMedianFeed(feedIds[i])
                    .metadata
                    .timestamp <
                publishTimes[i]
            ) {
                updatePriceFeeds(updateData);
                return;
            }
        }
        revert ErrorsLib.DataStale();
    }

    // function parsePriceFeedUpdates(
    //     bytes[] calldata updateData,
    //     bytes32[] calldata priceIds,
    //     uint64 minPublishTime,
    //     uint64 maxPublishTime
    // ) external payable returns (SpotMedian[] memory priceFeeds){

    // }

    // function parsePriceFeedUpdatesUnique(
    //     bytes[] calldata updateData,
    //     bytes32[] calldata priceIds,
    //     uint64 minPublishTime,
    //     uint64 maxPublishTime
    // ) external payable returns (SpotMedian[] memory priceFeeds) {

    // }

    function diff(uint x, uint y) internal pure returns (uint) {
        if (x > y) {
            return x - y;
        } else {
            return y - x;
        }
    }
}
