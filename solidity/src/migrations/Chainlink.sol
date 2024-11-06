import "@pragmaoracle/solidity-sdk/src/interfaces/IPragma.sol";
import "@pragmaoracle/solidity-sdk/src/interfaces/PragmaStructs.sol";

/**
 * @title An adapter of the ChainlinkAggregatorV3 interface that supports Pragma price feeds
 * Users should deploy an instance of this contract to wrap every price feed id that they need to use.
 */
contract PragmaAggregatorV3 {
    bytes32 public feedId;
    IPragma public pragmaInterface;

    constructor(address _pragma, bytes32 _feedId) {
        feedId = _feedId;
        pragmaInterface = IPragma(_pragma);
    }

    function updateFeeds(bytes[] calldata priceUpdateData) public payable {
        // Update the prices to the latest available values and pay the required fee for it. The `priceUpdateData` data
        // should be retrieved from the Theoros SDK, you can find additional information on https://docs.pragmaoracle.com/
        uint256 fee = pragmaInterface.getUpdateFee(priceUpdateData);
        pragmaInterface.updatePriceFeeds{value: fee}(priceUpdateData);

        // refund remaining eth
        payable(msg.sender).call{value: address(this).balance}("");
    }

    function decimals() public view virtual returns (uint8) {
        SpotMedian memory price = pragmaInterface.getSpotMedianFeed(feedId);
        return uint8(-1 * int8(price.decimals));
    }

    function description() public pure returns (string memory) {
        return "An adapter for Chainlink aggregator by PragmaV2";
    }

    function version() public pure returns (uint256) {
        return 1;
    }

    function latestAnswer() public view virtual returns (int256) {
        SpotMedian memory price = pragmaInterface.getSpotMedianFeed(feedId);
        return int256(price.price);
    }

    function latestTimestamp() public view returns (uint256) {
        SpotMedian memory price = pragmaInterface.getSpotMedianFeed(feedId);
        return price.metadata.timestamp;
    }

    function latestRound() public view returns (uint256) {
        // use timestamp as the round id
        return latestTimestamp();
    }

    function getAnswer(uint256) public view returns (int256) {
        return latestAnswer();
    }

    function getTimestamp(uint256) external view returns (uint256) {
        return latestTimestamp();
    }

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        SpotMedian memory price = pragmaInterface.getSpotMedianFeed(feedId);
        return (_roundId, int256(price.price), price.metadata.timestamp, price.metadata.timestamp, _roundId);
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        SpotMedian memory price = pragmaInterface.getSpotMedianFeed(feedId);
        roundId = uint80(price.metadata.timestamp);
        return (roundId, int256(price.price), price.metadata.timestamp, price.metadata.timestamp, roundId);
    }
}
