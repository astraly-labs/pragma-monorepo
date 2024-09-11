// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/libraries/DataParser.sol";

contract DataParserTest is Test {
    function testParseSpotMedianEntry() public pure {
        bytes memory feed_id = abi.encodePacked(
            uint8(0), ///CRYPTO
            uint16(0),  //SPOT
            bytes32("BTC/USD")
        );
        bytes memory data = abi.encodePacked(
            feed_id,
            uint64(1625097600), // timestamp
            uint16(3),
            uint8(8),
            uint256(35000 ether), // price
            uint256(100 ether) // volume
        );

        ParsedData memory result = DataParser.parse(data);

        assert(result.dataType == FeedType.SpotMedian);
        assertEq(result.spot.metadata.feed_id, feed_id);
        assertEq(result.spot.metadata.timestamp, 1625097600);
        assertEq(result.spot.metadata.number_of_sources, 3);
        assertEq(result.spot.metadata.decimals, 8);
        assertEq(result.spot.price, 35000 ether);
        assertEq(result.spot.volume, 100 ether);
    }

    function testParseTWAPEntry() public pure {
        bytes memory feed_id = abi.encodePacked(
            uint8(0), ///CRYPTO
            uint16(1),  //TWAP
            bytes32("ETH/USD")
        );
        bytes memory data = abi.encodePacked(
            feed_id,
            uint64(1625097600), // timestamp
            uint16(3),
            uint8(8),
            uint256(2000 ether), // twap_price
            uint256(3600), // time_period
            uint256(1950 ether), // start_price
            uint256(2050 ether), // end_price
            uint256(1000 ether), // total_volume
            uint256(100) // number_of_data_points
        );

        ParsedData memory result = DataParser.parse(data);

        assert (result.dataType == FeedType.Twap);
        assertEq(result.twap.metadata.timestamp, 1625097600);
        assertEq(result.twap.metadata.number_of_sources, 3);
        assertEq(result.twap.metadata.decimals, 8);
        assertEq(result.twap.metadata.feed_id, feed_id);
        assertEq(result.twap.twap_price, 2000 ether);
        assertEq(result.twap.time_period, 3600);
        assertEq(result.twap.start_price, 1950 ether);
        assertEq(result.twap.end_price, 2050 ether);
        assertEq(result.twap.total_volume, 1000 ether);
        assertEq(result.twap.number_of_data_points, 100);
    }

    function testParseRealizedVolatilityEntry() public pure {

        bytes memory feed_id = abi.encodePacked(
            uint8(0), ///CRYPTO
            uint16(2),  //RV
            bytes32("BTC/USD")
        );
        bytes memory data = abi.encodePacked(
            feed_id,
            uint64(1625097600), // timestamp
            uint16(3),
            uint8(8),
            uint256(0.5 ether), // volatility
            uint256(86400), // time_period
            uint256(34000 ether), // start_price
            uint256(36000 ether), // end_price
            uint256(37000 ether), // high_price
            uint256(33000 ether), // low_price
            uint256(1440) // number_of_data_points
        );

        ParsedData memory result = DataParser.parse(data);

        assert(result.dataType ==  FeedType.RealizedVolatility);
        assertEq(result.rv.metadata.timestamp, 1625097600);
        assertEq(result.rv.metadata.number_of_sources, 3);
        assertEq(result.rv.metadata.decimals, 8);
        assertEq(result.rv.metadata.feed_id, feed_id);
        assertEq(result.rv.volatility, 0.5 ether);
        assertEq(result.rv.time_period, 86400);
        assertEq(result.rv.start_price, 34000 ether);
        assertEq(result.rv.end_price, 36000 ether);
        assertEq(result.rv.high_price, 37000 ether);
        assertEq(result.rv.low_price, 33000 ether);
        assertEq(result.rv.number_of_data_points, 1440);
    }

    function testParseOptionsEntry() public pure {

        bytes memory feed_id = abi.encodePacked(
            uint8(0), ///CRYPTO
            uint16(3),  //Option
            bytes32("ETH/USD")
        );
        bytes memory data = abi.encodePacked(
           feed_id,
            uint64(1625097600), // timestamp
            uint16(3),
            uint8(8),
            uint256(2500 ether), // strike_price
            uint256(0.5 ether), // implied_volatility
            uint256(604800), // time_to_expiry
            uint8(1), // is_call
            uint256(2400 ether), // underlying_price
            uint256(150 ether), // option_price
            uint256(0.6 ether), // delta
            uint256(0.001 ether), // gamma
            uint256(1000 ether), // vega
            uint256(50 ether), // theta (positive value, will be negated in the contract)
            uint256(10 ether) // rho
        );

        ParsedData memory result = DataParser.parse(data);

        assert(result.dataType ==  FeedType.Options);
        assertEq(result.options.metadata.timestamp, 1625097600);
        assertEq(result.options.metadata.number_of_sources, 3);
        assertEq(result.options.metadata.decimals, 8);
        assertEq(result.options.metadata.feed_id, feed_id);
        assertEq(result.options.strike_price, 2500 ether);
        assertEq(result.options.implied_volatility, 0.5 ether);
        assertEq(result.options.time_to_expiry, 604800);
        assertTrue(result.options.is_call);
        assertEq(result.options.underlying_price, 2400 ether);
        assertEq(result.options.option_price, 150 ether);
        assertEq(result.options.delta, 0.6 ether);
        assertEq(result.options.gamma, 0.001 ether);
        assertEq(result.options.vega, 1000 ether);
        assertEq(result.options.theta, 50 ether); // Note: This is now positive in the test data
        assertEq(result.options.rho, 10 ether);
    }

    function testParsePerpEntry() public pure {

        bytes memory feed_id = abi.encodePacked(
            uint8(0), ///CRYPTO
            uint16(3),  //PERP
            bytes32("BTC/USD")
        );
        bytes memory data = abi.encodePacked(
            feed_id,
            uint64(1625097600), // timestamp
            uint16(3),
            uint8(8),
            uint256(35000 ether), // mark_price
            uint256(0.001 ether), // funding_rate
            uint256(1000 ether), // open_interest
            uint256(500 ether) // volume
        );

        ParsedData memory result = DataParser.parse(data);

        assert(result.dataType ==  FeedType.Perpetuals);
        assertEq(result.perp.metadata.timestamp, 1625097600);
        assertEq(result.perp.metadata.number_of_sources, 3);
        assertEq(result.perp.metadata.decimals, 8);
        assertEq(result.perp.metadata.feed_id, feed_id);
        assertEq(result.perp.mark_price, 35000 ether);
        assertEq(result.perp.funding_rate, 0.001 ether);
        assertEq(result.perp.open_interest, 1000 ether);
        assertEq(result.perp.volume, 500 ether);
    }

    function testParseUnknownDataType() public {
        bytes memory data = abi.encodePacked(
            uint16(9999) // Unknown data type
        );

        vm.expectRevert("Unknown data type");
        DataParser.parse(data);
    }
}
