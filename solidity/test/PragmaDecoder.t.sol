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

contract PragmaDecoderHarness is PragmaDecoder {
    constructor(
        address _hyperlane,
        uint16[] memory _dataSourceEmitterChainIds,
        bytes32[] memory _dataSourceEmitterAddresses
    ) PragmaDecoder(_hyperlane, _dataSourceEmitterChainIds, _dataSourceEmitterAddresses) {}

    function exposed_updateDataInfoFromUpdate(bytes calldata updateData) external returns (uint8) {
        return updateDataInfoFromUpdate(updateData);
    }

    function exposed_spotMedianFeeds(bytes memory dataId) external view returns (SpotMedian memory) {
        return spotMedianFeeds[dataId];
    }

    function exposed_twapFeeds(bytes memory dataId) external view returns (TWAP memory) {
        return twapFeeds[dataId];
    }

    function exposed_rvFeeds(bytes memory dataId) external view returns (RealizedVolatility memory) {
        return rvFeeds[dataId];
    }

    function exposed_optionsFeeds(bytes memory dataId) external view returns (Options memory) {
        return optionsFeeds[dataId];
    }

    function exposed_perpFeeds(bytes memory dataId) external view returns (Perp memory) {
        return perpFeeds[dataId];
    }

    function _isProofValid(
        bytes calldata encodedProof,
        uint256 offset,
        bytes32 root,
        bytes calldata leafData
    ) internal virtual override returns (bool valid, uint256 endOffset) {
        // valid set to true for testing
       unchecked {
            bytes32 currentDigest = MerkleTree.leafHash(leafData);
            uint256 proofOffset = 0;
            uint16 proofSizeArray = UnsafeCalldataBytesLib.toUint16(encodedProof, proofOffset);
            proofOffset +=2;
            for (uint256 i = 0; i < proofSizeArray; i++) {
                bytes32 siblingDigest = bytes32(UnsafeCalldataBytesLib.toBytes32(encodedProof, proofOffset));
                proofOffset += 32;  // TO CHECK

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
        _setUp(FeedType.SpotMedian, false);
         
    }

    function _setUp(FeedType dataType, bool is_multiple) public {
        address[][] memory validatorSets = new address[][](5);
        if (!is_multiple)
{
            // SPOT MEDIAN
            validatorSets[0] = new address[](5);
            validatorSets[0][0] = address(0x000ef4d3842fab2e93a7432204161279295cfb56be);
            validatorSets[0][1] = address(0x0057b4de4c28740eb6a4f8366c19135b524d8585af);
            validatorSets[0][2] = address(0x00f4fea01052a71f6f00d2b970ae69cf2260609aed);
            validatorSets[0][3] = address(0x00a5a173cb34486bae04959be51a206d828bcd1bc3);
            validatorSets[0][4] = address(0x007051cc33689c3d1a26404eedd1a9a03622cc7d77);

        // TWAP

            validatorSets[1] = new address[](5);
            validatorSets[1][0] = address(0x008fa8c74a65136cbcdd2626b68ca3eb8eea63acfc);
            validatorSets[1][1] = address(0x000bca088eec72533a3a4980480ade06faafe1f50f);
            validatorSets[1][2] = address(0x00e45163f8e455309f1e6867a2c84a08784216f9a6);
            validatorSets[1][3] = address(0x00bc0efa2f350f6d361d3966bbd8097141abfae9a6);
            validatorSets[1][4] = address(0x00d1830991b42ffc44ecdaf031cfef11983168c880);
            
            // Realized volatility

            validatorSets[2] = new address[](5);
            validatorSets[2][0] = address(0x00899fa4ffe896b3dc242eef434729bb3dce51fdf0);
            validatorSets[2][1] = address(0x00113ea1a998d83c04b56bc43e45c659f49515640d);
            validatorSets[2][2] = address(0x000c322d77a5fafc1605dcf0619e13d268922d9f84);
            validatorSets[2][3] = address(0x00b4187559a872c643d01d98f346f06af2ffc545b8);
            validatorSets[2][4] = address(0x00e1cd2d3467cede6cb3599eb5929a01bfcc0cce46);
            // Options

            validatorSets[3] = new address[](5);
            validatorSets[3][0] = address(0x002ee99bdbf7f92437d44a1726c695233faf0f12a2);
            validatorSets[3][1] = address(0x004664224a07be4f9a638389a446bc8fbc6c53aa30);
            validatorSets[3][2] = address(0x0041438e3f52b967b074f688f44e3a03d29d16a4de);
            validatorSets[3][3] = address(0x00648026ce5f492db0c411e5990658fce52ac68e14);
            validatorSets[3][4] = address(0x001b6253cc165c4e19c468451a61c371114ac794bd);
            // Perp

            validatorSets[4] = new address[](5);
            validatorSets[4][0] = address(0x000cdafa30d7e008dc97f5589c67cfc2ff210e3997);
            validatorSets[4][1] = address(0x00d7389b2a2cadaafb296f1d43f5253266dd413ef5);
            validatorSets[4][2] = address(0x002445ad199e1976fe87d0a436128454baa9a51ded);
            validatorSets[4][3] = address(0x002a71bcf2deff27d96b4bd1f3db58230bbe1d8906);
            validatorSets[4][4] = address(0x0016659cb6d1c9b56a2a74f97d54daa014d4f152df);
}
else {
     // SPOT MEDIAN
            validatorSets[0] = new address[](5);
            validatorSets[0][0] = address(0x000ef4d3842fab2e93a7432204161279295cfb56be);
            validatorSets[0][1] = address(0x0057b4de4c28740eb6a4f8366c19135b524d8585af);
            validatorSets[0][2] = address(0x00f4fea01052a71f6f00d2b970ae69cf2260609aed);
            validatorSets[0][3] = address(0x00a5a173cb34486bae04959be51a206d828bcd1bc3);
            validatorSets[0][4] = address(0x007051cc33689c3d1a26404eedd1a9a03622cc7d77);

        // TWAP

            validatorSets[1] = new address[](5);
            validatorSets[1][0] = address(0x008fa8c74a65136cbcdd2626b68ca3eb8eea63acfc);
            validatorSets[1][1] = address(0x000bca088eec72533a3a4980480ade06faafe1f50f);
            validatorSets[1][2] = address(0x00e45163f8e455309f1e6867a2c84a08784216f9a6);
            validatorSets[1][3] = address(0x00bc0efa2f350f6d361d3966bbd8097141abfae9a6);
            validatorSets[1][4] = address(0x00d1830991b42ffc44ecdaf031cfef11983168c880);
            
            // Realized volatility

            validatorSets[2] = new address[](5);
            validatorSets[2][0] = address(0x00899fa4ffe896b3dc242eef434729bb3dce51fdf0);
            validatorSets[2][1] = address(0x00113ea1a998d83c04b56bc43e45c659f49515640d);
            validatorSets[2][2] = address(0x000c322d77a5fafc1605dcf0619e13d268922d9f84);
            validatorSets[2][3] = address(0x00b4187559a872c643d01d98f346f06af2ffc545b8);
            validatorSets[2][4] = address(0x00e1cd2d3467cede6cb3599eb5929a01bfcc0cce46);
            // Options

            validatorSets[3] = new address[](5);
            validatorSets[3][0] = address(0x002ee99bdbf7f92437d44a1726c695233faf0f12a2);
            validatorSets[3][1] = address(0x004664224a07be4f9a638389a446bc8fbc6c53aa30);
            validatorSets[3][2] = address(0x0041438e3f52b967b074f688f44e3a03d29d16a4de);
            validatorSets[3][3] = address(0x00648026ce5f492db0c411e5990658fce52ac68e14);
            validatorSets[3][4] = address(0x001b6253cc165c4e19c468451a61c371114ac794bd);
            // Perp

            validatorSets[4] = new address[](5);
            validatorSets[4][0] = address(0x000cdafa30d7e008dc97f5589c67cfc2ff210e3997);
            validatorSets[4][1] = address(0x00d7389b2a2cadaafb296f1d43f5253266dd413ef5);
            validatorSets[4][2] = address(0x002445ad199e1976fe87d0a436128454baa9a51ded);
            validatorSets[4][3] = address(0x002a71bcf2deff27d96b4bd1f3db58230bbe1d8906);
            validatorSets[4][4] = address(0x0016659cb6d1c9b56a2a74f97d54daa014d4f152df);
}
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
        bool is_multiple = false;
        _setUp(FeedType.SpotMedian, is_multiple);
        bytes memory encodedUpdate = createEncodedUpdate(FeedType.SpotMedian, "ETH/USD",is_multiple);
        uint8 numUpdates = pragmaDecoder.exposed_updateDataInfoFromUpdate(encodedUpdate);

        assertEq(numUpdates, 1, "Number of updates should be 1");


        bytes memory feedId = abi.encodePacked(
            uint8(0), ///CRYPTO
            uint16(0),  //SPOT
            bytes32("ETH/USD")
        );

        SpotMedian memory spotMedian = pragmaDecoder.exposed_spotMedianFeeds(feedId);

        assertEq(spotMedian.metadata.timestamp, block.timestamp, "Timestamp should match");
        assertEq(spotMedian.metadata.number_of_sources, 5, "Number of sources should be 5");
        assertEq(spotMedian.metadata.decimals, 8, "Decimals should be 8");
        assertEq(spotMedian.metadata.feed_id, feedId, "Feed ID should match");
        assertEq(spotMedian.price, 2000 * 1e8, "Price should match");
        assertEq(spotMedian.volume, 1000 * 1e18, "Volume should match");

        assertEq(pragmaDecoder.latestPublishTimes(feedId), block.timestamp, "Latest publish time should be updated");
    }

    function testUpdateDataInfoFromUpdateTWAP() public {
        bool is_multiple = false;
        _setUp(FeedType.Twap, is_multiple);
        bytes memory encodedUpdate = createEncodedUpdate(FeedType.Twap, "BTC/USD" ,is_multiple);
        uint8 numUpdates = pragmaDecoder.exposed_updateDataInfoFromUpdate(encodedUpdate);

        assertEq(numUpdates, 1, "Number of updates should be 1");

                bytes memory feedId = abi.encodePacked(
            uint8(0), ///CRYPTO
            uint16(1),  //TWAP
            bytes32("BTC/USD")
        );
        
        TWAP memory twap = pragmaDecoder.exposed_twapFeeds(feedId);

        assertEq(twap.metadata.timestamp, block.timestamp, "Timestamp should match");
        assertEq(twap.metadata.number_of_sources, 5, "Number of sources should be 5");
        assertEq(twap.metadata.decimals, 8, "Decimals should be 8");
        assertEq(twap.metadata.feed_id,feedId, "Feed ID should match");
        assertEq(twap.twap_price, 30000 * 1e8, "TWAP price should match");
        assertEq(twap.time_period, 3600, "Time period should match");
        assertEq(twap.start_price, 29000 * 1e8, "Start price should match");
        assertEq(twap.end_price, 31000 * 1e8, "End price should match");
        assertEq(twap.total_volume, 1000 * 1e18, "Total volume should match");
        assertEq(twap.number_of_data_points, 60, "Number of data points should match");

        assertEq(pragmaDecoder.latestPublishTimes(feedId), block.timestamp, "Latest publish time should be updated");
    }

    function testUpdateDataInfoFromUpdateRealizedVolatility() public {
        bool is_multiple = false;
        _setUp(FeedType.RealizedVolatility,is_multiple);
        bytes memory feedId = abi.encodePacked(
            uint8(0), ///CRYPTO
            uint16(2),  //RV
            bytes32("ETH/USD")
        );        RealizedVolatility memory rv = pragmaDecoder.exposed_rvFeeds(feedId);
        bytes memory encodedUpdate = createEncodedUpdate(FeedType.RealizedVolatility, feedId,is_multiple);
        uint8 numUpdates = pragmaDecoder.exposed_updateDataInfoFromUpdate(encodedUpdate);

        assertEq(numUpdates, 1, "Number of updates should be 1");


        assertEq(rv.metadata.timestamp, block.timestamp, "Timestamp should match");
        assertEq(rv.metadata.number_of_sources, 5, "Number of sources should be 5");
        assertEq(rv.metadata.decimals, 8, "Decimals should be 8");
        assertEq(rv.metadata.feed_id, feedId, "Feed id ID should match");
        assertEq(rv.volatility, 50 * 1e6, "Volatility should match"); // 50% volatility
        assertEq(rv.time_period, 86400, "Time period should match");
        assertEq(rv.start_price, 1900 * 1e8, "Start price should match");
        assertEq(rv.end_price, 2100 * 1e8, "End price should match");
        assertEq(rv.high_price, 2200 * 1e8, "High price should match");
        assertEq(rv.low_price, 1800 * 1e8, "Low price should match");
        assertEq(rv.number_of_data_points, 1440, "Number of data points should match");

        assertEq(pragmaDecoder.latestPublishTimes(feedId), block.timestamp, "Latest publish time should be updated");
    }

    function testUpdateDataInfoFromUpdateOptions() public {
        bool is_multiple=false;
        _setUp(FeedType.Options,is_multiple);
        bytes memory encodedUpdate = createEncodedUpdate(FeedType.Options, "ETH/USD",is_multiple);
        uint8 numUpdates = pragmaDecoder.exposed_updateDataInfoFromUpdate(encodedUpdate);

        assertEq(numUpdates, 1, "Number of updates should be 1");

        bytes32 dataId = keccak256("ETH/USD");
        Options memory options = pragmaDecoder.exposed_optionsFeeds(dataId);

        assertEq(options.metadata.timestamp, block.timestamp, "Timestamp should match");
        assertEq(options.metadata.number_of_sources, 5, "Number of sources should be 5");
        assertEq(options.metadata.decimals, 8, "Decimals should be 8");
        assertEq(options.metadata.pair_id, bytes32("ETH/USD"), "Pair ID should match");
        assertEq(options.strike_price, 2000 * 1e8, "Strike price should match");
        assertEq(options.implied_volatility, 50 * 1e6, "Implied volatility should match");
        assertEq(options.time_to_expiry, 604800, "Time to expiry should match");
        assertEq(options.is_call, true, "Option type should be call");
        assertEq(options.underlying_price, 1950 * 1e8, "Underlying price should match");
        assertEq(options.option_price, 100 * 1e8, "Option price should match");
        assertEq(options.delta, 60 * 1e6, "Delta should match");
        assertEq(options.gamma, 2 * 1e6, "Gamma should match");
        assertEq(options.vega, 10 * 1e6, "Vega should match");
        assertEq(options.theta, -5 * 1e6, "Theta should match");
        assertEq(options.rho, 3 * 1e6, "Rho should match");

        assertEq(pragmaDecoder.latestPublishTimes(dataId), block.timestamp, "Latest publish time should be updated");
    }

    function testUpdateDataInfoFromUpdatePerp() public {
        bool is_multiple = false;
        _setUp(FeedType.Perpetuals,is_multiple);
        bytes memory encodedUpdate = createEncodedUpdate(FeedType.Perpetuals, "ETH/USD",is_multiple);
        uint8 numUpdates = pragmaDecoder.exposed_updateDataInfoFromUpdate(encodedUpdate);

        assertEq(numUpdates, 1, "Number of updates should be 1");

        bytes32 dataId = keccak256("ETH/USD");
        Perp memory perp = pragmaDecoder.exposed_perpFeeds(dataId);

        assertEq(perp.metadata.timestamp, block.timestamp, "Timestamp should match");
        assertEq(perp.metadata.number_of_sources, 5, "Number of sources should be 5");
        assertEq(perp.metadata.decimals, 8, "Decimals should be 8");
        assertEq(perp.metadata.pair_id, bytes32("ETH/USD"), "Pair ID should match");
        assertEq(perp.mark_price, 2000 * 1e8, "Mark price should match");
        assertEq(perp.funding_rate, 1 * 1e6, "Funding rate should match"); // 0.1% funding rate
        assertEq(perp.open_interest, 10000 * 1e18, "Open interest should match");
        assertEq(perp.volume, 50000 * 1e18, "Volume should match");

        assertEq(pragmaDecoder.latestPublishTimes(dataId), block.timestamp, "Latest publish time should be updated");
    }

    // function testMultipleUpdatesInSingleCall() public {
    //     bytes memory encodedUpdate = createMultipleEncodedUpdates();
    //     uint8 numUpdates = pragmaDecoder.exposed_updateDataInfoFromUpdate(encodedUpdate);

    //     assertEq(numUpdates, 3, "Number of updates should be 3");

    //     // Check SpotMedian update
    //     bytes32 spotDataId = keccak256("ETH/USD");
    //     SpotMedian memory spotMedian = pragmaDecoder.exposed_spotMedianFeeds(spotDataId);
    //     assertEq(spotMedian.metadata.timestamp, block.timestamp, "SpotMedian timestamp should match");
    //     assertEq(spotMedian.price, 2000 * 1e8, "SpotMedian price should match");

    //     // Check TWAP update
    //     bytes32 twapDataId = keccak256("BTC/USD");
    //     TWAP memory twap = pragmaDecoder.exposed_twapFeeds(twapDataId);
    //     assertEq(twap.metadata.timestamp, block.timestamp, "TWAP timestamp should match");
    //     assertEq(twap.twap_price, 30000 * 1e8, "TWAP price should match");

    //     // Check Options update
    //     bytes32 optionsDataId = keccak256("ETH-OPTIONS");
    //     Options memory options = pragmaDecoder.exposed_optionsFeeds(optionsDataId);
    //     assertEq(options.metadata.timestamp, block.timestamp, "Options timestamp should match");
    //     assertEq(options.option_price, 100 * 1e8, "Option price should match");
    // }

    // Helper functions to create encoded updates
    function createEncodedUpdate(FeedType dataType, bytes memory feedId, bool is_multiple) internal view returns (bytes memory) {

        bytes memory updateData = abi.encodePacked(
            feedId,
            uint64(block.timestamp), // timestamp
            uint16(5), // number_of_sources
            uint8(8) // decimals
        );
        if (dataType == FeedType.SpotMedian) {
            updateData = abi.encodePacked(
                updateData,
                uint256(2000 * 1e8), // price
                uint256(1000 * 1e18) // volume
            );
        } else if (dataType == FeedType.Twap) {
            updateData = abi.encodePacked(
                updateData,
                uint256(30000 * 1e8), // twap_price
                uint256(3600), // time_period
                uint256(29000 * 1e8), // start_price
                uint256(31000 * 1e8), // end_price
                uint256(1000 * 1e18), // total_volume
                uint256(60) // number_of_data_points
            );
        } else if (dataType == FeedType.RealizedVolatility) {
            updateData = abi.encodePacked(
                updateData,
                uint256(50 * 1e6), // volatility
                uint256(86400), // time_period
                uint256(1900 * 1e8), // start_price
                uint256(2100 * 1e8), // end_price
                uint256(2200 * 1e8), // high_price
                uint256(1800 * 1e8), // low_price
                uint256(1440) // number_of_data_points
            );
        } else if (dataType == FeedType.Options) {
            updateData = abi.encodePacked(
                updateData,
                uint256(2000 * 1e8), // strike_price
                uint256(50 * 1e6), // implied_volatility
                uint256(604800), // time_to_expiry
                true, // is_call
                uint256(1950 * 1e8), // underlying_price
                uint256(100 * 1e8), // option_price
                uint256(60 * 1e6), // delta
                uint256(2 * 1e6), // gamma
                uint256(10 * 1e6), // vega
                int256(-5 * 1e6), // theta
                uint256(3 * 1e6) // rho
            );
        } else if (dataType == FeedType.Perpetuals) {
            updateData = abi.encodePacked(
                updateData,
                uint256(2000 * 1e8), // mark_price
                uint256(1 * 1e6), // funding_rate
                uint256(10000 * 1e18), // open_interest
                uint256(50000 * 1e18) // volume
            );
        }

        bytes memory proof = abi.encodePacked(
            uint16(3),  // proof length in array
            bytes32(0x1012312123213123213231231233421341341234134142341123331123123123),
            bytes32(0x1012312312312312312311231233434342421414123413413123331123123123),
            bytes32(0x1012312312312312312312323324234234234234324234212123331123123123)
        );


        bytes memory hyMsgPayload = abi.encodePacked(
            bytes32(uint256(1)), // checkpointRoot
            uint8(1), // numUpdates
            uint16(updateData.length), // updateSize
            uint16(proof.length),
            proof,
            updateData,
            bytes32(0x1234),  // dataId
            uint64(block.timestamp) // publishTime
        );

        bytes memory hyMsg = createHyperlaneMessage(hyMsgPayload, is_multiple);

        return abi.encodePacked(
            uint8(1), // majorVersion
            uint8(0), // minorVersion
            uint8(0), // trailingHeaderSize
            uint16(hyMsg.length), // hyMsgSize
            hyMsg
        );
    }


    function extractUpdateData(bytes memory encodedUpdate) internal pure returns (bytes memory) {
        // Skip the header (22 bytes) and extract the update data
        return encodedUpdate.slice(22, encodedUpdate.length - 22);
    }


    function createHyperlaneMessage(bytes memory payload, bool is_multiple) internal view returns (bytes memory) {
        bytes memory signatures = abi.encodePacked(
            uint8(5), // number of signatures
            uint8(0),
            bytes32(0x83db08d4e1590714aef8600f5f1e3c967ab6a3b9f93bb4242de0306510e688ea),
            bytes32(0x0af5d1d51ea7e51a291789ff4866a1e36bc4134d956870799380d2d71f5dbf3d),
            uint8(27),
            uint8(1),
            bytes32(0xf81a5dd3f871ad2d27a3b538e73663d723f8263fb3d289514346d43d000175f5),
            bytes32(0x083df770623e9ae52a7bb154473961e24664bb003bdfdba6100fb5e540875ce1),
            uint8(27),
            uint8(2),
            bytes32(0x76b194f951f94492ca582dab63dc413b9ac1ca9992c22bc2186439e9ab8fdd3c),
            bytes32(0x62a6a6f402edaa53e9bdc715070a61edb0d98d4e14e182f60bdd4ae932b40b29),
            uint8(27),
            uint8(3),
            bytes32(0x35932eefd85897d868aaacd4ba7aee81a2384e42ba062133f6d37fdfebf94ad4),
            bytes32(0x78cce49db96ee27c3f461800388ac95101476605baa64a194b7dd4d56d2d4a4d),
            uint8(27),
            uint8(4),
            bytes32(0x6b38d4353d69396e91c57542254348d16459d448ab887574e9476a6ff76d49a1),
            bytes32(0x3527627295bde423d7d799afef22affac4f00c70a5b651ad14c8879aeb9b6e03),
            uint8(27)
        );

        bytes memory body = abi.encodePacked(
            uint32(0), // nonce
            uint64(block.timestamp), // timestamp
            uint16(1), // emitterChainId
            bytes32(uint256(0x1234)), // emitterAddress
            payload
        );


        bytes32 hash = keccak256(abi.encodePacked(keccak256(body)));

        return abi.encodePacked(
            uint8(1), // version
            signatures,
            uint32(0), // nonce
            uint64(block.timestamp), // timestamp
            uint16(1), // emitterChainId
            bytes32(uint256(0x1234)), // emitterAddress
            payload
        );
    }
}