// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/libraries/DataParser.sol";

contract DataParserTest is Test {
    function testParseSpotMedianEntry() public pure {
        bytes memory data = abi.encodePacked(
            uint16(21325), // SM
            uint64(1625097600), // timestamp
            uint16(3), 
            uint8(8),
            bytes32("BTC/USD"),
            uint256(35000 ether), // price
            uint256(100 ether) // volume
        );

        ParsedData memory result = DataParser.parse(data);
        
        assertEq(result.dataType, 21325);
        assertEq(result.spotEntry.metadata.timestamp, 1625097600);
        assertEq(result.spotEntry.metadata.number_of_sources, 3);
        assertEq(result.spotEntry.metadata.decimals, 8);
        assertEq(result.spotEntry.pair_id, bytes32("BTC/USD"));
        assertEq(result.spotEntry.price, 35000 ether);
        assertEq(result.spotEntry.volume, 100 ether);
    }

    function testParseTWAPEntry() public pure {
        bytes memory data = abi.encodePacked(
            uint16(21591), // TW
            uint64(1625097600), // timestamp
            uint16(3), 
            uint8(8),
            bytes32("ETH/USD"),
            uint256(2000 ether), // twap_price
            uint256(3600), // time_period
            uint256(1950 ether), // start_price
            uint256(2050 ether), // end_price
            uint256(1000 ether), // total_volume
            uint256(100) // number_of_data_points
        );

        ParsedData memory result = DataParser.parse(data);
        
        assertEq(result.dataType, 21591);
        assertEq(result.twapEntry.metadata.timestamp, 1625097600);
        assertEq(result.twapEntry.metadata.number_of_sources, 3);
        assertEq(result.twapEntry.metadata.decimals, 8);
        assertEq(result.twapEntry.pair_id, bytes32("ETH/USD"));
        assertEq(result.twapEntry.twap_price, 2000 ether);
        assertEq(result.twapEntry.time_period, 3600);
        assertEq(result.twapEntry.start_price, 1950 ether);
        assertEq(result.twapEntry.end_price, 2050 ether);
        assertEq(result.twapEntry.total_volume, 1000 ether);
        assertEq(result.twapEntry.number_of_data_points, 100);
    }

    function testParseRealizedVolatilityEntry() public pure {
        bytes memory data = abi.encodePacked(
            uint16(21078), // RV
            uint64(1625097600), // timestamp
            uint16(3), 
            uint8(8),
            bytes32("BTC/USD"),
            uint256(0.5 ether), // volatility
            uint256(86400), // time_period
            uint256(34000 ether), // start_price
            uint256(36000 ether), // end_price
            uint256(37000 ether), // high_price
            uint256(33000 ether), // low_price
            uint256(1440) // number_of_data_points
        );

        ParsedData memory result = DataParser.parse(data);
        
        assertEq(result.dataType, 21078);
        assertEq(result.rvEntry.metadata.timestamp, 1625097600);
        assertEq(result.rvEntry.metadata.number_of_sources, 3);
        assertEq(result.rvEntry.metadata.decimals, 8);
        assertEq(result.rvEntry.pair_id, bytes32("BTC/USD"));
        assertEq(result.rvEntry.volatility, 0.5 ether);
        assertEq(result.rvEntry.time_period, 86400);
        assertEq(result.rvEntry.start_price, 34000 ether);
        assertEq(result.rvEntry.end_price, 36000 ether);
        assertEq(result.rvEntry.high_price, 37000 ether);
        assertEq(result.rvEntry.low_price, 33000 ether);
        assertEq(result.rvEntry.number_of_data_points, 1440);
    }

    function testParseOptionsEntry() public pure {
        bytes memory data = abi.encodePacked(
            uint16(20304), // OP
            uint64(1625097600), // timestamp
            uint16(3), 
            uint8(8),
            bytes32("ETH/USD"),
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
        
        assertEq(result.dataType, 20304);
        assertEq(result.optionsEntry.metadata.timestamp, 1625097600);
        assertEq(result.optionsEntry.metadata.number_of_sources, 3);
        assertEq(result.optionsEntry.metadata.decimals, 8);
        assertEq(result.optionsEntry.pair_id, bytes32("ETH/USD"));
        assertEq(result.optionsEntry.strike_price, 2500 ether);
        assertEq(result.optionsEntry.implied_volatility, 0.5 ether);
        assertEq(result.optionsEntry.time_to_expiry, 604800);
        assertTrue(result.optionsEntry.is_call);
        assertEq(result.optionsEntry.underlying_price, 2400 ether);
        assertEq(result.optionsEntry.option_price, 150 ether);
        assertEq(result.optionsEntry.delta, 0.6 ether);
        assertEq(result.optionsEntry.gamma, 0.001 ether);
        assertEq(result.optionsEntry.vega, 1000 ether);
        assertEq(result.optionsEntry.theta, 50 ether); // Note: This is now positive in the test data
        assertEq(result.optionsEntry.rho, 10 ether);
    }

    function testParsePerpEntry() public pure {
        bytes memory data = abi.encodePacked(
            uint16(20560), // PP
            uint64(1625097600), // timestamp
            uint16(3), 
            uint8(8),
            bytes32("BTC/USD"),
            uint256(35000 ether), // mark_price
            uint256(0.001 ether), // funding_rate
            uint256(1000 ether), // open_interest
            uint256(500 ether) // volume
        );

        ParsedData memory result = DataParser.parse(data);
        
        assertEq(result.dataType, 20560);
        assertEq(result.perpEntry.metadata.timestamp, 1625097600);
        assertEq(result.perpEntry.metadata.number_of_sources, 3);
        assertEq(result.perpEntry.metadata.decimals, 8);
        assertEq(result.perpEntry.pair_id, bytes32("BTC/USD"));
        assertEq(result.perpEntry.mark_price, 35000 ether);
        assertEq(result.perpEntry.funding_rate, 0.001 ether);
        assertEq(result.perpEntry.open_interest, 1000 ether);
        assertEq(result.perpEntry.volume, 500 ether);
    }

    function testParseUnknownDataType() public {
        bytes memory data = abi.encodePacked(
            uint16(9999) // Unknown data type
        );

        vm.expectRevert("Unknown data type");
        DataParser.parse(data);
    }
}