// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./../src/DataParser.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ParsedData} from "./../src/interfaces/IDataParser.sol";

contract DataParserV1Test is Test {
    DataParserV1 public dataParser;
    address public admin;
    uint256 public constant MIN_DELAY = 1 days;

    function setUp() public {
        admin = address(this);
        dataParser = new DataParserV1();
        dataParser.initialize(admin, MIN_DELAY);
    }

    function testInitialization() public {
        assertTrue(address(dataParser.timelock()) != address(0), "Timelock not initialized");
        assertEq(dataParser.owner(), address(dataParser.timelock()), "Ownership not transferred to timelock");
    }

    function testParseSpotData() public {
        // Prepare sample spot data
        bytes memory spotData = abi.encodePacked(
            uint16(21325), // SM
            uint64(1625097600), // timestamp
            bytes32("SOURCE"), // source
            bytes32("PUBLISHER"), // publisher
            uint8(7), // pair_id length
            "BTC/USD", // pair_id
            uint256(35000 * 1e18), // price
            uint256(100 * 1e18) // volume
        );

        ParsedData memory result = dataParser.parse(spotData);

        assertEq(result.dataType, 21325, "Incorrect data type");
        assertEq(result.spotEntry.base_entry.timestamp, 1625097600, "Incorrect timestamp");
        assertEq(result.spotEntry.pair_id, "BTC/USD", "Incorrect pair_id");
        assertEq(result.spotEntry.price, 35000 * 1e18, "Incorrect price");
        assertEq(result.spotEntry.volume, 100 * 1e18, "Incorrect volume");
    }

    function testParseTWAPData() public {
        // Prepare sample TWAP data
        bytes memory twapData = abi.encodePacked(
            uint16(21591), // TW
            uint64(1625097600), // timestamp
            bytes32("SOURCE"), // source
            bytes32("PUBLISHER"), // publisher
            uint8(7), // pair_id length
            "ETH/USD", // pair_id
            uint256(2500 * 1e18), // twap_price
            uint256(3600), // time_period
            uint256(2450 * 1e18), // start_price
            uint256(2550 * 1e18), // end_price
            uint256(1000 * 1e18), // total_volume
            uint256(60) // number_of_data_points
        );

        ParsedData memory result = dataParser.parse(twapData);

        assertEq(result.dataType, 21591, "Incorrect data type");
        assertEq(result.twapEntry.base_entry.timestamp, 1625097600, "Incorrect timestamp");
        assertEq(result.twapEntry.pair_id, "ETH/USD", "Incorrect pair_id");
        assertEq(result.twapEntry.twap_price, 2500 * 1e18, "Incorrect TWAP price");
        assertEq(result.twapEntry.time_period, 3600, "Incorrect time period");
    }

    function testParseInvalidDataType() public {
        // Prepare invalid data type
        bytes memory invalidData = abi.encodePacked(uint16(9999));

        vm.expectRevert("DataParserV1: Unknown data type");
        dataParser.parse(invalidData);
    }

    function testTimelockUpgrade() public {
        address newImplementation = address(new DataParserV1());

        // Prepare the upgrade call
        bytes memory data = abi.encodeWithSelector(
            UUPSUpgradeable(address(dataParser)).upgradeToAndCall.selector,
            newImplementation,
            ""
        );

        // Schedule the upgrade
        dataParser.timelock().schedule(
            address(dataParser),
            0,
            data,
            bytes32(0),
            bytes32(0),
            MIN_DELAY
        );

        // Try to upgrade immediately (should fail)
        vm.expectRevert("TimelockController: operation is not ready");
        dataParser.timelock().execute(
            address(dataParser),
            0,
            data,
            bytes32(0),
            bytes32(0)
        );

        // Wait for the delay
        vm.warp(block.timestamp + MIN_DELAY);

        // Execute the upgrade
        dataParser.timelock().execute(
            address(dataParser),
            0,
            data,
            bytes32(0),
            bytes32(0)
        );

        // Verify the upgrade
        assertEq(UUPSUpgradeable(address(dataParser)).implementation(), newImplementation, "Upgrade failed");
    }
}