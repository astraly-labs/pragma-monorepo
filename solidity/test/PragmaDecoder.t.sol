// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/PragmaDecoder.sol";
import "../src/libraries/DataParser.sol";
import "../src/interfaces/IHyperlane.sol";
import "../src/libraries/ErrorsLib.sol";
import "./../src/Hyperlane.sol";
import "../src/libraries/BytesLib.sol";
import "forge-std/console2.sol";
import {TestUtils} from "./TestUtils.sol";

contract PragmaDecoderHarness is PragmaDecoder {
    constructor(
        address _hyperlane,
        uint16[] memory _dataSourceEmitterChainIds,
        bytes32[] memory _dataSourceEmitterAddresses
    ) PragmaDecoder(_hyperlane, _dataSourceEmitterChainIds, _dataSourceEmitterAddresses) {}

    function exposed_updateDataInfoFromUpdate(bytes calldata updateData) external returns (uint8) {
        return updateDataInfoFromUpdate(updateData);
    }

    function exposed_spotMedianFeeds(bytes32 dataId) external view returns (SpotMedian memory) {
        return spotMedianFeeds[dataId];
    }

    function exposed_twapFeeds(bytes32 dataId) external view returns (TWAP memory) {
        return twapFeeds[dataId];
    }

    function exposed_rvFeeds(bytes32 dataId) external view returns (RealizedVolatility memory) {
        return rvFeeds[dataId];
    }

    function exposed_optionsFeeds(bytes32 dataId) external view returns (Options memory) {
        return optionsFeeds[dataId];
    }

    function exposed_latestPriceInfo(bytes32 dataId) external view returns (DataFeed memory) {
        return _latestPriceInfo[dataId];
    }

    function exposed_latestPublishTimes(bytes32 dataId) external view returns (uint64) {
        return latestPublishTimes[dataId];
    }

    function exposed_perpFeeds(bytes32 dataId) external view returns (Perp memory) {
        return perpFeeds[dataId];
    }

    function _isProofValid(bytes calldata encodedProof, uint256 offset, bytes32 root, bytes calldata leafData)
        internal
        virtual
        override
        returns (bool valid, uint256 endOffset)
    {
        // valid set to true for testing
        unchecked {
            bytes32 currentDigest = MerkleTree.leafHash(leafData);
            uint256 proofOffset = 0;
            uint16 proofSizeArray = UnsafeCalldataBytesLib.toUint16(encodedProof, proofOffset);
            proofOffset += 2;
            for (uint256 i = 0; i < proofSizeArray; i++) {
                bytes32 siblingDigest = bytes32(UnsafeCalldataBytesLib.toBytes32(encodedProof, proofOffset));
                proofOffset += 32; // TO CHECK

                currentDigest = MerkleTree.nodeHash(currentDigest, siblingDigest);
            }
            valid = true;
            endOffset = offset + proofOffset;
        }
    }
}

contract PragmaDecoderTest is Test {
    PragmaDecoderHarness private pragmaDecoder;

    using BytesLib for bytes;

    function setUpHyperlane(uint8 numValidators, address[] memory initSigners) public returns (address) {
        if (initSigners.length == 0) {
            initSigners = new address[](numValidators);
        }
        Hyperlane hyperlane_ = new Hyperlane(initSigners);
        return address(hyperlane_);
    }

    function setUp() public {
        // Default setup with a specific data type, e.g., FeedType.SpotMedian
        _setUp(FeedType.SpotMedian);
    }

    function _setUp(FeedType dataType) public {
        address[][] memory validatorSets = new address[][](5);
        // SPOT MEDIAN
        validatorSets[0] = new address[](5);
        validatorSets[0][0] = address(0x00168068bae701a75eacce4c41ddbe379289e8f8ae);
        validatorSets[0][1] = address(0x0061beeef8bfa33c8e179950889e76b060e074ffa7);
        validatorSets[0][2] = address(0x0069d27c84c3c027856d478ab03dd193d5716a13e3);
        validatorSets[0][3] = address(0x0006bfa6bb0a40fabc6d56b376011ae985bd1eda41);
        validatorSets[0][4] = address(0x007963989f4fefaecba30c8edce53dd47cedb487c2);

        // TWAP

        validatorSets[1] = new address[](5);
        validatorSets[1][0] = address(0x005472c2afb8c5d5bdedd6fb15538aba4e5e954b68);
        validatorSets[1][1] = address(0x009ee8d4936be96299e8eba08b99fc70962c56d476);
        validatorSets[1][2] = address(0x00e04aa374e71c6b42009660ca18d64d48f1b49567);
        validatorSets[1][3] = address(0x0093eeea4ec6424ca2f0fd2d5473a5b109b36e8aba);
        validatorSets[1][4] = address(0x00d80848530176c5ec4d389d0a4a31c48710a51a11);

        // Realized volatility

        validatorSets[2] = new address[](5);
        validatorSets[2][0] = address(0x0081113a12d0677bfd9055722826be0608a79e485f);
        validatorSets[2][1] = address(0x0075c554efa4c4061f5319cce671342c3a5ee7ca4f);
        validatorSets[2][2] = address(0x00ac532f8758c2562be11476fea2a0c5a03e49ed1c);
        validatorSets[2][3] = address(0x00b4902be8b8e9a3b2c1a2dda4b503caa6669935ec);
        validatorSets[2][4] = address(0x00b472cd1688acb23bbe561353ad0a7d6be287b4f8);
        // Options

        validatorSets[3] = new address[](5);
        validatorSets[3][0] = address(0x000d1bd3a53d455401d7e9b35f2ebefa1e86d879f5);
        validatorSets[3][1] = address(0x00059c488fdac0d66ccb790db20ac3881f2f81a0c6);
        validatorSets[3][2] = address(0x003e961cf87c7e0d13b848f0654b6d37faea1e5666);
        validatorSets[3][3] = address(0x006b78b4d7b33a15edd8bbc5b3b1e679ad3e6c0d27);
        validatorSets[3][4] = address(0x009cc8b348632e9f38e88ebd2ca564542c4b7297c5);

        // Perp

        validatorSets[4] = new address[](5);
        validatorSets[4][0] = address(0x0054ef2963f3e6b6a77fffc3f7bbd5fc0e479412c2);
        validatorSets[4][1] = address(0x000b78cc20dc1b484781c56d0ea806f34693833bd5);
        validatorSets[4][2] = address(0x003dbecdde82fd8c8823daf0841bd1e75342588a41);
        validatorSets[4][3] = address(0x004f437c9e4c5cbbe927945838601b8277d68e69e6);
        validatorSets[4][4] = address(0x00fa73934abc5b756599d973d2906b2db58f506284);

        uint8 validatorSetIndex;
        if (dataType == FeedType.SpotMedian) {
            validatorSetIndex = 0;
        } else if (dataType == FeedType.Twap) {
            validatorSetIndex = 1;
        } else if (dataType == FeedType.RealizedVolatility) {
            validatorSetIndex = 2;
        } else if (dataType == FeedType.Options) {
            validatorSetIndex = 3;
        } else if (dataType == FeedType.Perpetuals) {
            validatorSetIndex = 4;
        } else {
            revert("Invalid data type");
        }

        // Set up the Hyperlane contract with the provided validator
        IHyperlane hyperlane =
            IHyperlane(setUpHyperlane(uint8(validatorSets[validatorSetIndex].length), validatorSets[validatorSetIndex]));

        uint16[] memory chainIds = new uint16[](1);
        chainIds[0] = 1;

        bytes32[] memory emitterAddresses = new bytes32[](1);
        emitterAddresses[0] = bytes32(uint256(0x1234));

        pragmaDecoder = new PragmaDecoderHarness(address(hyperlane), chainIds, emitterAddresses);
    }

    function testUpdateDataInfoFromUpdateSpotMedian() public {
        _setUp(FeedType.SpotMedian);
        bytes32 feedId = bytes32(
            abi.encodePacked(
                uint16(0),
                ///CRYPTO
                uint16(0), //SPOT
                bytes32("ETH/USD")
            )
        );
        bytes memory encodedUpdate = TestUtils.createEncodedUpdate(FeedType.SpotMedian, feedId);
        uint8 numUpdates = pragmaDecoder.exposed_updateDataInfoFromUpdate(encodedUpdate);

        assertEq(numUpdates, 1, "Number of updates should be 1");

        SpotMedian memory spotMedian = pragmaDecoder.exposed_spotMedianFeeds(feedId);

        assertEq(spotMedian.metadata.timestamp, block.timestamp, "Timestamp should match");
        assertEq(spotMedian.metadata.numberOfSources, 5, "Number of sources should be 5");
        assertEq(spotMedian.metadata.decimals, 8, "Decimals should be 8");
        assertEq(spotMedian.metadata.feedId, feedId, "Feed ID should match");
        assertEq(spotMedian.price, 2000 * 1e8, "Price should match");
        assertEq(spotMedian.volume, 1000 * 1e18, "Volume should match");

        DataFeed memory dataFeed = pragmaDecoder.exposed_latestPriceInfo(feedId);
        assertEq(dataFeed.value, 2000 * 1e8, "Price should match");
        assertEq(dataFeed.numSourcesAggregated, 5, "Number of sources should be 5");
        assertEq(dataFeed.publishTime, block.timestamp, "Timestamp should match");
        assertEq(dataFeed.feedId, feedId, "Feed id should match");

        assertEq(pragmaDecoder.latestPublishTimes(feedId), block.timestamp, "Latest publish time should be updated");
    }

    function testUpdateDataInfoFromUpdateTWAP() public {
        _setUp(FeedType.Twap);
        bytes32 feedId = bytes32(
            abi.encodePacked(
                uint16(0),
                ///CRYPTO
                uint16(1), //TWAP
                bytes32("BTC/USD")
            )
        );
        bytes memory encodedUpdate = TestUtils.createEncodedUpdate(FeedType.Twap, feedId);
        uint8 numUpdates = pragmaDecoder.exposed_updateDataInfoFromUpdate(encodedUpdate);

        assertEq(numUpdates, 1, "Number of updates should be 1");

        TWAP memory twap = pragmaDecoder.exposed_twapFeeds(feedId);

        assertEq(twap.metadata.timestamp, block.timestamp, "Timestamp should match");
        assertEq(twap.metadata.numberOfSources, 5, "Number of sources should be 5");
        assertEq(twap.metadata.decimals, 8, "Decimals should be 8");
        assertEq(twap.metadata.feedId, feedId, "Feed ID should match");
        assertEq(twap.twapPrice, 30000 * 1e8, "TWAP price should match");
        assertEq(twap.timePeriod, 3600, "Time period should match");
        assertEq(twap.startPrice, 29000 * 1e8, "Start price should match");
        assertEq(twap.endPrice, 31000 * 1e8, "End price should match");
        assertEq(twap.totalVolume, 1000 * 1e18, "Total volume should match");
        assertEq(twap.numberOfDataPoints, 60, "Number of data points should match");

        DataFeed memory dataFeed = pragmaDecoder.exposed_latestPriceInfo(feedId);
        assertEq(dataFeed.value, 30000 * 1e8, "TWAP Price should match");
        assertEq(dataFeed.numSourcesAggregated, 5, "Number of sources should be 5");
        assertEq(dataFeed.publishTime, block.timestamp, "Timestamp should match");
        assertEq(dataFeed.feedId, feedId, "Feed id should match");

        assertEq(pragmaDecoder.latestPublishTimes(feedId), block.timestamp, "Latest publish time should be updated");
    }

    function testUpdateDataInfoFromUpdateRealizedVolatility() public {
        _setUp(FeedType.RealizedVolatility);
        bytes32 feedId = bytes32(
            abi.encodePacked(
                uint16(0),
                ///CRYPTO
                uint16(2), //RV
                bytes32("ETH/USD")
            )
        );
        bytes memory encodedUpdate = TestUtils.createEncodedUpdate(FeedType.RealizedVolatility, feedId);
        uint8 numUpdates = pragmaDecoder.exposed_updateDataInfoFromUpdate(encodedUpdate);
        RealizedVolatility memory rv = pragmaDecoder.exposed_rvFeeds(feedId);

        assertEq(numUpdates, 1, "Number of updates should be 1");
        assertEq(rv.metadata.timestamp, block.timestamp, "Timestamp should match");
        assertEq(rv.metadata.numberOfSources, 5, "Number of sources should be 5");
        assertEq(rv.metadata.decimals, 8, "Decimals should be 8");
        assertEq(rv.metadata.feedId, feedId, "Feed id ID should match");
        assertEq(rv.volatility, 50 * 1e6, "Volatility should match"); // 50% volatility
        assertEq(rv.timePeriod, 86400, "Time period should match");
        assertEq(rv.startPrice, 1900 * 1e8, "Start price should match");
        assertEq(rv.endPrice, 2100 * 1e8, "End price should match");
        assertEq(rv.high_price, 2200 * 1e8, "High price should match");
        assertEq(rv.low_price, 1800 * 1e8, "Low price should match");
        assertEq(rv.numberOfDataPoints, 1440, "Number of data points should match");

        DataFeed memory dataFeed = pragmaDecoder.exposed_latestPriceInfo(feedId);
        assertEq(dataFeed.value, 2100 * 1e8, "RV Price should match");
        assertEq(dataFeed.numSourcesAggregated, 5, "Number of sources should be 5");
        assertEq(dataFeed.publishTime, block.timestamp, "Timestamp should match");
        assertEq(dataFeed.feedId, feedId, "Feed id should match");

        assertEq(pragmaDecoder.latestPublishTimes(feedId), block.timestamp, "Latest publish time should be updated");
    }

    function testUpdateDataInfoFromUpdateOptions() public {
        _setUp(FeedType.Options);
        bytes32 feedId = bytes32(
            abi.encodePacked(
                uint16(0),
                ///CRYPTO
                uint16(3), //Options
                bytes32("ETH/USD")
            )
        );
        bytes memory encodedUpdate = TestUtils.createEncodedUpdate(FeedType.Options, feedId);
        uint8 numUpdates = pragmaDecoder.exposed_updateDataInfoFromUpdate(encodedUpdate);

        assertEq(numUpdates, 1, "Number of updates should be 1");

        Options memory options = pragmaDecoder.exposed_optionsFeeds(feedId);

        assertEq(options.metadata.timestamp, block.timestamp, "Timestamp should match");
        assertEq(options.metadata.numberOfSources, 5, "Number of sources should be 5");
        assertEq(options.metadata.decimals, 8, "Decimals should be 8");
        assertEq(options.metadata.feedId, feedId, "Feed ID should match");
        assertEq(options.strikePrice, 2000 * 1e8, "Strike price should match");
        assertEq(options.impliedVolatility, 50 * 1e6, "Implied volatility should match");
        assertEq(options.timeToExpiry, 604800, "Time to expiry should match");
        assertEq(options.isCall, true, "Option type should be call");
        assertEq(options.underlyingPrice, 1950 * 1e8, "Underlying price should match");
        assertEq(options.optionPrice, 100 * 1e8, "Option price should match");
        assertEq(options.delta, 60 * 1e6, "Delta should match");
        assertEq(options.gamma, 2 * 1e6, "Gamma should match");
        assertEq(options.vega, 10 * 1e6, "Vega should match");
        assertEq(options.theta, -5 * 1e6, "Theta should match");
        assertEq(options.rho, 3 * 1e6, "Rho should match");

        DataFeed memory dataFeed = pragmaDecoder.exposed_latestPriceInfo(feedId);
        assertEq(dataFeed.value, 100 * 1e8, "RV Price should match");
        assertEq(dataFeed.numSourcesAggregated, 5, "Number of sources should be 5");
        assertEq(dataFeed.publishTime, block.timestamp, "Timestamp should match");
        assertEq(dataFeed.feedId, feedId, "Feed id should match");

        assertEq(pragmaDecoder.latestPublishTimes(feedId), block.timestamp, "Latest publish time should be updated");
    }

    function testUpdateDataInfoFromUpdatePerp() public {
        _setUp(FeedType.Perpetuals);
        bytes32 feedId = bytes32(
            abi.encodePacked(
                uint16(0),
                ///CRYPTO
                uint16(4), //Perp
                bytes32("ETH/USD")
            )
        );
        bytes memory encodedUpdate = TestUtils.createEncodedUpdate(FeedType.Perpetuals, feedId);
        uint8 numUpdates = pragmaDecoder.exposed_updateDataInfoFromUpdate(encodedUpdate);

        assertEq(numUpdates, 1, "Number of updates should be 1");
        Perp memory perp = pragmaDecoder.exposed_perpFeeds(feedId);

        assertEq(perp.metadata.timestamp, block.timestamp, "Timestamp should match");
        assertEq(perp.metadata.numberOfSources, 5, "Number of sources should be 5");
        assertEq(perp.metadata.decimals, 8, "Decimals should be 8");
        assertEq(perp.metadata.feedId, feedId, "Feed ID should match");
        assertEq(perp.markPrice, 2000 * 1e8, "Mark price should match");
        assertEq(perp.fundingRate, 1 * 1e6, "Funding rate should match"); // 0.1% funding rate
        assertEq(perp.openInterest, 10000 * 1e18, "Open interest should match");
        assertEq(perp.volume, 50000 * 1e18, "Volume should match");

        DataFeed memory dataFeed = pragmaDecoder.exposed_latestPriceInfo(feedId);
        assertEq(dataFeed.value, 2000 * 1e8, "Mark Price should match");
        assertEq(dataFeed.numSourcesAggregated, 5, "Number of sources should be 5");
        assertEq(dataFeed.publishTime, block.timestamp, "Timestamp should match");
        assertEq(dataFeed.feedId, feedId, "Feed id should match");
        assertEq(pragmaDecoder.latestPublishTimes(feedId), block.timestamp, "Latest publish time should be updated");
    }
}
