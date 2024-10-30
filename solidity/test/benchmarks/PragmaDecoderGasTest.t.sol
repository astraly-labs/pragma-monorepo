// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../src/PragmaDecoder.sol";
import "../TestUtils.sol";
import "../PragmaDecoder.t.sol";

contract PragmaDecoderGasTest is Test {
    PragmaHarness private pragmaHarness;

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
        pragmaHarness = PragmaHarness(TestUtils.configurePragmaContract(dataType));
    }

    function testGasAllUpdates() public {
        string[5] memory updateTypes = ["SpotMedian", "TWAP", "RealizedVolatility", "Options", "Perpetuals"];
        uint256[5] memory currencies = [
            uint256(0x4554482f555344),
            uint256(0x4254432f555344),
            uint256(0x4254432f555344),
            uint256(0x4254432f555344),
            uint256(0x4254432f555344)
        ];
        for (uint256 i = 0; i < updateTypes.length; i++) {
            FeedType dataType = FeedType(i);
            _setUp(dataType);

            bytes32 feedId = bytes32(
                abi.encodePacked(
                    uint16(0), // CRYPTO
                    uint8(i), // Data type index
                    uint8(0),
                    currencies[i]
                )
            );
            bytes memory encodedUpdate = TestUtils.createEncodedUpdate(dataType, feedId);

            uint256 gasBefore = gasleft();
            pragmaHarness.exposed_updateDataInfoFromUpdate(encodedUpdate);
            uint256 gasUsed = gasBefore - gasleft();

            console.log(string(abi.encodePacked("Gas used for ", updateTypes[i], " update: ", vm.toString(gasUsed))));
        }
    }
}
