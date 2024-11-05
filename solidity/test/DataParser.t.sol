// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/libraries/DataParser.sol";
import "../src/libraries/ErrorsLib.sol";
import "./utils/TestConstants.sol";

contract DataParserTest is Test {
    function testParseSpotMedianEntry() public pure {
        bytes32 feedId = bytes32(
            abi.encodePacked(
                TestConstantsLib.CRYPTO, TestConstantsLib.SPOT, TestConstantsLib.UNIQUE, TestConstantsLib.BTC_USD
            )
        );
        bytes memory data = abi.encodePacked(
            feedId,
            uint64(1625097600), // timestamp
            uint16(3),
            uint8(8),
            uint256(35000 ether), // price
            uint256(100 ether) // volume
        );

        ParsedData memory result = DataParser.parse(data);

        assert(result.dataType == FeedType.SpotMedian);
        assertEq(result.spot.metadata.feedId, feedId);
        assertEq(result.spot.metadata.timestamp, 1625097600);
        assertEq(result.spot.metadata.numberOfSources, 3);
        assertEq(result.spot.metadata.decimals, 8);
        assertEq(result.spot.price, 35000 ether);
        assertEq(result.spot.volume, 100 ether);
    }

    function testParseTWAPEntry() public pure {
        bytes32 feedId = bytes32(
            abi.encodePacked(
                TestConstantsLib.CRYPTO, TestConstantsLib.TWAP, TestConstantsLib.UNIQUE, TestConstantsLib.ETH_USD
            )
        );
        bytes memory data = abi.encodePacked(
            feedId,
            uint64(1625097600), // timestamp
            uint16(3),
            uint8(8),
            uint256(2000 ether), // twapPrice
            uint256(3600), // timePeriod
            uint256(1950 ether), // startPrice
            uint256(2050 ether), // endPrice
            uint256(1000 ether), // totalVolume
            uint256(100) // numberOfDataPoints
        );

        ParsedData memory result = DataParser.parse(data);

        assert(result.dataType == FeedType.Twap);
        assertEq(result.twap.metadata.timestamp, 1625097600);
        assertEq(result.twap.metadata.numberOfSources, 3);
        assertEq(result.twap.metadata.decimals, 8);
        assertEq(result.twap.metadata.feedId, feedId);
        assertEq(result.twap.twapPrice, 2000 ether);
        assertEq(result.twap.timePeriod, 3600);
        assertEq(result.twap.startPrice, 1950 ether);
        assertEq(result.twap.endPrice, 2050 ether);
        assertEq(result.twap.totalVolume, 1000 ether);
        assertEq(result.twap.numberOfDataPoints, 100);
    }

    function testParseRealizedVolatilityEntry() public pure {
        bytes32 feedId = bytes32(
            abi.encodePacked(
                TestConstantsLib.CRYPTO,
                TestConstantsLib.REALIZED_VOLATILITY,
                TestConstantsLib.UNIQUE,
                TestConstantsLib.BTC_USD
            )
        );
        bytes memory data = abi.encodePacked(
            feedId,
            uint64(1625097600), // timestamp
            uint16(3),
            uint8(8),
            uint256(0.5 ether), // volatility
            uint256(86400), // timePeriod
            uint256(34000 ether), // startPrice
            uint256(36000 ether), // endPrice
            uint256(37000 ether), // highPrice
            uint256(33000 ether), // lowPrice
            uint256(1440) // numberOfDataPoints
        );

        ParsedData memory result = DataParser.parse(data);

        assert(result.dataType == FeedType.RealizedVolatility);
        assertEq(result.rv.metadata.timestamp, 1625097600);
        assertEq(result.rv.metadata.numberOfSources, 3);
        assertEq(result.rv.metadata.decimals, 8);
        assertEq(result.rv.metadata.feedId, feedId);
        assertEq(result.rv.volatility, 0.5 ether);
        assertEq(result.rv.timePeriod, 86400);
        assertEq(result.rv.startPrice, 34000 ether);
        assertEq(result.rv.endPrice, 36000 ether);
        assertEq(result.rv.highPrice, 37000 ether);
        assertEq(result.rv.lowPrice, 33000 ether);
        assertEq(result.rv.numberOfDataPoints, 1440);
    }

    function testParseOptionsEntry() public pure {
        bytes32 feedId = bytes32(
            abi.encodePacked(
                TestConstantsLib.CRYPTO, TestConstantsLib.OPTIONS, TestConstantsLib.UNIQUE, TestConstantsLib.ETH_USD
            )
        );
        bytes memory data = abi.encodePacked(
            feedId,
            uint64(1625097600), // timestamp
            uint16(3),
            uint8(8),
            uint256(2500 ether), // strikePrice
            uint256(0.5 ether), // impliedVolatility
            uint256(604800), // timeToExpiry
            uint8(1), // isCall
            uint256(2400 ether), // underlyingPrice
            uint256(150 ether), // optionPrice
            uint256(0.6 ether), // delta
            uint256(0.001 ether), // gamma
            uint256(1000 ether), // vega
            uint256(50 ether), // theta (positive value, will be negated in the contract)
            uint256(10 ether) // rho
        );

        ParsedData memory result = DataParser.parse(data);

        assert(result.dataType == FeedType.Options);
        assertEq(result.options.metadata.timestamp, 1625097600);
        assertEq(result.options.metadata.numberOfSources, 3);
        assertEq(result.options.metadata.decimals, 8);
        assertEq(result.options.metadata.feedId, feedId);
        assertEq(result.options.strikePrice, 2500 ether);
        assertEq(result.options.impliedVolatility, 0.5 ether);
        assertEq(result.options.timeToExpiry, 604800);
        assertTrue(result.options.isCall);
        assertEq(result.options.underlyingPrice, 2400 ether);
        assertEq(result.options.optionPrice, 150 ether);
        assertEq(result.options.delta, 0.6 ether);
        assertEq(result.options.gamma, 0.001 ether);
        assertEq(result.options.vega, 1000 ether);
        assertEq(result.options.theta, 50 ether); // Note: This is now positive in the test data
        assertEq(result.options.rho, 10 ether);
    }

    function testParsePerpEntry() public pure {
        bytes32 feedId = bytes32(
            abi.encodePacked(
                TestConstantsLib.CRYPTO, TestConstantsLib.PERP, TestConstantsLib.UNIQUE, TestConstantsLib.BTC_USD
            )
        );
        bytes memory data = abi.encodePacked(
            feedId,
            uint64(1625097600), // timestamp
            uint16(3),
            uint8(8),
            uint256(35000 ether), // markPrice
            uint256(0.001 ether), // fundingRate
            uint256(1000 ether), // openInterest
            uint256(500 ether) // volume
        );

        ParsedData memory result = DataParser.parse(data);

        assert(result.dataType == FeedType.Perpetuals);
        assertEq(result.perp.metadata.timestamp, 1625097600);
        assertEq(result.perp.metadata.numberOfSources, 3);
        assertEq(result.perp.metadata.decimals, 8);
        assertEq(result.perp.metadata.feedId, feedId);
        assertEq(result.perp.markPrice, 35000 ether);
        assertEq(result.perp.fundingRate, 0.001 ether);
        assertEq(result.perp.openInterest, 1000 ether);
        assertEq(result.perp.volume, 500 ether);
    }

    function testParseUnknownDataType() public {
        bytes32 feedId = bytes32(
            abi.encodePacked(
                TestConstantsLib.CRYPTO,
                uint8(20), //Unkown data type
                TestConstantsLib.UNIQUE,
                TestConstantsLib.BTC_USD
            )
        );
        bytes memory data = abi.encodePacked(
            feedId,
            uint64(1625097600), // timestamp
            uint16(3),
            uint8(8),
            uint256(35000 ether), // markPrice
            uint256(0.001 ether), // fundingRate
            uint256(1000 ether), // openInterest
            uint256(500 ether) // volume
        );
        vm.expectRevert(abi.encodeWithSignature("InvalidDataFeedType()"));
        DataParser.parse(data);
    }
}
