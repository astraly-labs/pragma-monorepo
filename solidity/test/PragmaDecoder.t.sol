// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/PragmaDecoder.sol";
import "../src/Pragma.sol";
import "../src/libraries/DataParser.sol";
import "../src/interfaces/IHyperlane.sol";
import "../src/libraries/ErrorsLib.sol";
import "./../src/Hyperlane.sol";
import "../src/libraries/BytesLib.sol";
import {TestUtils, PragmaHarness} from "./TestUtils.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "./mocks/PragmaUpgraded.sol";
import "./utils/TestConstants.sol";

contract PragmaHarnessTest is Test {
    PragmaHarness private pragmaHarness;

    using BytesLib for bytes;

    function setUp() public {
        // Default setup with a specific data type, e.g., FeedType.SpotMedian
        _setUp(FeedType.SpotMedian);
    }

    function _setUp(FeedType dataType) public {
        // Default setup with a specific data type, e.g., FeedType.SpotMedian
        pragmaHarness = PragmaHarness(TestUtils.configurePragmaContract(dataType));
    }

    function setupRaw() public {
        pragmaHarness = PragmaHarness(TestUtils.configurePragmaRawContract());
    }

    function testUpdateRawFeed() public {
        setupRaw();
        // encoded update
        bytes memory encodedUpdate =
            hex"0100000170030100c1ec5070f1a4868b8e6bfa5bbd31ac77605c5af1a739bc4e7758d4ca1d88fa8835c1460646b647c4c4403b324c2297a04d70b84888dc873021f80d6d70ed015e1c00031b8b0000000067225b1100611a3d0060240f2bccef7e64f920eec05c5bfffbc48c6ceaa4efca8748772b60cbafc30536953cdd0dd5b8e24428e4fb6eab5c143daba15f62b24606e50d822508faefd53032e26a3b1d1510dfe82a2ab8d6c0fc0f010dcdd3c410ba2f9fdad3479b1400031b8b15704e0efd1955cfe1c1182ba083bd5309707bdd795397cbbbb106cfc9b29bb001000100000000000000000000004254432f555344000000000000000000000000000000000000000067225b1100080800000000000000000000068aa5cb9d63000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004254432f5553440000000067225b11";
        uint8 numUpdates = pragmaHarness.exposed_updateDataInfoFromUpdate(encodedUpdate);
        assertEq(numUpdates, 1, "Number of updates should be 1");
    }

    function testUpdateDataInfoFromUpdateSpotMedian() public {
        _setUp(FeedType.SpotMedian);
        bytes32 feedId = bytes32(
            abi.encodePacked(
                uint16(0),
                ///CRYPTO
                uint8(0), //SPOT
                uint8(0), //VARIANT
                TestConstantsLib.ETH_USD
            )
        );

        bytes memory encodedUpdate = TestUtils.createEncodedUpdate(FeedType.SpotMedian, feedId);
        uint8 numUpdates = pragmaHarness.exposed_updateDataInfoFromUpdate(encodedUpdate);

        assertEq(numUpdates, 1, "Number of updates should be 1");

        SpotMedian memory spotMedian = pragmaHarness.exposed_spotMedianFeeds(feedId);

        assertEq(spotMedian.metadata.timestamp, block.timestamp, "Timestamp should match");
        assertEq(spotMedian.metadata.numberOfSources, 5, "Number of sources should be 5");
        assertEq(spotMedian.metadata.decimals, 8, "Decimals should be 8");
        assertEq(spotMedian.metadata.feedId, feedId, "Feed ID should match");
        assertEq(spotMedian.price, 2000 * 1e8, "Price should match");
        assertEq(spotMedian.volume, 1000 * 1e18, "Volume should match");
    }

    function testUpdateDataInfoFromUpdateTWAP() public {
        _setUp(FeedType.Twap);
        bytes32 feedId = bytes32(
            abi.encodePacked(
                uint16(0),
                ///CRYPTO
                uint8(1), //TWAP
                uint8(0), // VARIANT,
                TestConstantsLib.BTC_USD
            )
        );
        bytes memory encodedUpdate = TestUtils.createEncodedUpdate(FeedType.Twap, feedId);
        uint8 numUpdates = pragmaHarness.exposed_updateDataInfoFromUpdate(encodedUpdate);

        assertEq(numUpdates, 1, "Number of updates should be 1");

        TWAP memory twap = pragmaHarness.exposed_twapFeeds(feedId);

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
    }

    function testUpdateDataInfoFromUpdateRealizedVolatility() public {
        _setUp(FeedType.RealizedVolatility);
        bytes32 feedId = bytes32(
            abi.encodePacked(
                uint16(0),
                ///CRYPTO
                uint8(2), //RV
                uint8(0), //VARIANT
                TestConstantsLib.BTC_USD
            )
        );
        bytes memory encodedUpdate = TestUtils.createEncodedUpdate(FeedType.RealizedVolatility, feedId);
        uint8 numUpdates = pragmaHarness.exposed_updateDataInfoFromUpdate(encodedUpdate);
        RealizedVolatility memory rv = pragmaHarness.exposed_rvFeeds(feedId);

        assertEq(numUpdates, 1, "Number of updates should be 1");
        assertEq(rv.metadata.timestamp, block.timestamp, "Timestamp should match");
        assertEq(rv.metadata.numberOfSources, 5, "Number of sources should be 5");
        assertEq(rv.metadata.decimals, 8, "Decimals should be 8");
        assertEq(rv.metadata.feedId, feedId, "Feed id ID should match");
        assertEq(rv.volatility, 50 * 1e6, "Volatility should match"); // 50% volatility
        assertEq(rv.timePeriod, 86400, "Time period should match");
        assertEq(rv.startPrice, 1900 * 1e8, "Start price should match");
        assertEq(rv.endPrice, 2100 * 1e8, "End price should match");
        assertEq(rv.highPrice, 2200 * 1e8, "High price should match");
        assertEq(rv.lowPrice, 1800 * 1e8, "Low price should match");
        assertEq(rv.numberOfDataPoints, 1440, "Number of data points should match");
    }

    function testUpdateDataInfoFromUpdateOptions() public {
        _setUp(FeedType.Options);
        bytes32 feedId = bytes32(
            abi.encodePacked(
                uint16(0),
                ///CRYPTO
                uint8(3), //Options
                uint8(0),
                TestConstantsLib.BTC_USD
            )
        );
        bytes memory encodedUpdate = TestUtils.createEncodedUpdate(FeedType.Options, feedId);
        uint8 numUpdates = pragmaHarness.exposed_updateDataInfoFromUpdate(encodedUpdate);

        assertEq(numUpdates, 1, "Number of updates should be 1");

        Options memory options = pragmaHarness.exposed_optionsFeeds(feedId);

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
    }

    function testUpdateDataInfoFromUpdatePerp() public {
        _setUp(FeedType.Perpetuals);
        bytes32 feedId = bytes32(
            abi.encodePacked(
                uint16(0),
                ///CRYPTO
                uint8(4), //Perp
                uint8(0), //VARIANT
                TestConstantsLib.BTC_USD
            )
        );
        bytes memory encodedUpdate = TestUtils.createEncodedUpdate(FeedType.Perpetuals, feedId);
        uint8 numUpdates = pragmaHarness.exposed_updateDataInfoFromUpdate(encodedUpdate);

        assertEq(numUpdates, 1, "Number of updates should be 1");
        Perp memory perp = pragmaHarness.exposed_perpFeeds(feedId);

        assertEq(perp.metadata.timestamp, block.timestamp, "Timestamp should match");
        assertEq(perp.metadata.numberOfSources, 5, "Number of sources should be 5");
        assertEq(perp.metadata.decimals, 8, "Decimals should be 8");
        assertEq(perp.metadata.feedId, feedId, "Feed ID should match");
        assertEq(perp.markPrice, 2000 * 1e8, "Mark price should match");
        assertEq(perp.fundingRate, 1 * 1e6, "Funding rate should match"); // 0.1% funding rate
        assertEq(perp.openInterest, 10000 * 1e18, "Open interest should match");
        assertEq(perp.volume, 50000 * 1e18, "Volume should match");
    }
}

contract PragmaUpgradeableTest is Test {
    PragmaHarness public pragma_;
    Hyperlane public mockHyperlane;
    address public owner;
    address public user;

    function setUp() public {
        pragma_ = PragmaHarness(TestUtils.configurePragmaContract(FeedType.SpotMedian));
        owner = address(this);
        user = address(0x1);
    }

    function testInitialState() public {
        assertEq(pragma_.owner(), owner);
        assertEq(pragma_.validTimePeriodSeconds(), 120);
        assertEq(pragma_.singleUpdateFeeInWei(), 0.1 ether);
    }

    function testUpgrade() public {
        // Upgrade to V2
        PragmaUpgraded pragmaV2 = new PragmaUpgraded();
        pragma_.upgradeToAndCall(address(pragmaV2), "");

        // Check if upgrade was successful
        assertEq(PragmaUpgraded(address(pragma_)).version(), "2.0.0");
    }

    function testUpgradeRevertNonOwner() public {
        PragmaUpgraded pragmaV2 = new PragmaUpgraded();

        vm.prank(user);
        vm.expectRevert();
        pragma_.upgradeToAndCall(address(pragmaV2), "");
    }

    function testStatePreservationAfterUpgrade() public {
        // Set some state before upgrade
        pragma_.updateDataFeeds(new bytes[](0)); // Assuming this function exists and sets some state

        // Upgrade to V2
        PragmaUpgraded pragmaV2 = new PragmaUpgraded();
        pragma_.upgradeToAndCall(address(pragmaV2), "");

        // Check if state is maintained
        assertEq(PragmaUpgraded(address(pragma_)).validTimePeriodSeconds(), 120);
        assertEq(PragmaUpgraded(address(pragma_)).singleUpdateFeeInWei(), 0.1 ether);
        // Add more checks for other state variables
    }

    function testNewFunctionAfterUpgrade() public {
        // Upgrade to V2
        PragmaUpgraded pragmaV2 = new PragmaUpgraded();
        pragma_.upgradeToAndCall(address(pragmaV2), "");

        // Call new function
        assertEq(PragmaUpgraded(address(pragma_)).version(), "2.0.0");
    }

    function _getChainIds() internal pure returns (uint32[] memory) {
        uint32[] memory chainIds = new uint32[](2);
        chainIds[0] = 1;
        chainIds[1] = 2;
        return chainIds;
    }

    function _getEmitterAddresses() internal pure returns (bytes32[] memory) {
        bytes32[] memory emitterAddresses = new bytes32[](2);
        emitterAddresses[0] = bytes32("emitter1");
        emitterAddresses[1] = bytes32("emitter2");
        return emitterAddresses;
    }
}
