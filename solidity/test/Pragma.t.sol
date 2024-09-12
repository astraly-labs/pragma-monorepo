// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {IPragma} from "../src/interfaces/IPragma.sol";
// import "./utils/PragmaTestUtils.t.sol";
// import "forge-std/Test.sol";
// import "../src/Pragma.sol";
// import "../src/libraries/ErrorsLib.sol";

// contract PragmaTest is Test {
//     IPragma public pragmaInstance;
//     address constant HYPERLANE = address(0x1);
//     uint16[] dataSourceEmitterChainIds;
//     bytes32[] dataSourceEmitterAddresses;
//     uint256 constant VALID_TIME_PERIOD = 3600; // 1 hour
//     uint256 constant SINGLE_UPDATE_FEE = 0.01 ether;

//     function setUp() public {
//         dataSourceEmitterChainIds = new uint16[](1);
//         dataSourceEmitterChainIds[0] = 1;

//         dataSourceEmitterAddresses = new bytes32[](1);
//         dataSourceEmitterAddresses[0] = bytes32(uint256(uint160(address(this))));

//         pragmaInstance = new Pragma(
//             HYPERLANE,
//             dataSourceEmitterChainIds,
//             dataSourceEmitterAddresses,
//             VALID_TIME_PERIOD,
//             SINGLE_UPDATE_FEE
//         );
//     }

//     function testUpdateDataFeeds() public {
//         bytes[] memory updateData = new bytes[](1);
//         updateData[0] = abi.encodePacked(bytes32("TEST_FEED"), uint64(block.timestamp), uint256(100 ether));

//         uint256 requiredFee = SINGLE_UPDATE_FEE;
//         pragmaInstance.updateDataFeeds{value: requiredFee}(updateData);

//         assertTrue(pragmaInstance.dataFeedExists(bytes32("TEST_FEED")));
//     }

//     function testUpdateDataFeedsInsufficientFee() public {
//         bytes[] memory updateData = new bytes[](1);
//         updateData[0] = abi.encodePacked(bytes32("TEST_FEED"), uint64(block.timestamp), uint256(100 ether));

//         uint256 insufficientFee = SINGLE_UPDATE_FEE - 1 wei;
//         vm.expectRevert(ErrorsLib.InsufficientFee.selector);
//         pragmaInstance.updateDataFeeds{value: insufficientFee}(updateData);
//     }

//     function testGetPriceNoOlderThan() public {
//         bytes32 feedId = bytes32("TEST_FEED");
//         uint64 publishTime = uint64(block.timestamp);
//         uint256 price = 100 ether;

//         bytes[] memory updateData = new bytes[](1);
//         updateData[0] = abi.encodePacked(feedId, publishTime, price);

//         pragmaInstance.updateDataFeeds{value: SINGLE_UPDATE_FEE}(updateData);

//         DataFeed memory data = pragmaInstance.getPriceNoOlderThan(feedId, 60); // 60 seconds
//         // assertEq(data.value, price);
//     }

//     function testGetPriceNoOlderThanStaleData() public {
//         bytes32 feedId = bytes32("TEST_FEED");
//         uint64 publishTime = uint64(block.timestamp - 3601); // 1 hour and 1 second ago
//         uint256 price = 100 ether;

//         bytes[] memory updateData = new bytes[](1);
//         updateData[0] = abi.encodePacked(feedId, publishTime, price);

//         pragmaInstance.updateDataFeeds{value: SINGLE_UPDATE_FEE}(updateData);

//         vm.warp(block.timestamp + 3601);
//         vm.expectRevert(ErrorsLib.DataStale.selector);
//         pragmaInstance.getPriceNoOlderThan(feedId, 3600); // 1 hour
//     }

//     function testDataFeedExists() public {
//         bytes32 feedId = bytes32("TEST_FEED");
//         assertFalse(pragmaInstance.dataFeedExists(feedId));

//         bytes[] memory updateData = new bytes[](1);
//         updateData[0] = abi.encodePacked(feedId, uint64(block.timestamp), uint256(100 ether));

//         pragmaInstance.updateDataFeeds{value: SINGLE_UPDATE_FEE}(updateData);

//         assertTrue(pragmaInstance.dataFeedExists(feedId));
//     }

//     function testGetValidTimePeriod() public {
//         assertEq(pragmaInstance.getValidTimePeriod(), VALID_TIME_PERIOD);
//     }

//     function testVersion() public {
//         assertEq(pragmaInstance.version(), "1.0.0");
//     }

//     receive() external payable {}
// }

