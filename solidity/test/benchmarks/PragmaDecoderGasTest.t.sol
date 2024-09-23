// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../src/PragmaDecoder.sol";
import "../TestUtils.sol";
import "../PragmaDecoder.t.sol";

contract PragmaDecoderGasTest is Test {
    PragmaDecoderHarness private pragmaDecoder;

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
        validatorSets[1][0] = address(0x00a7aac8c81227f598ae6ef3e9a50e5dcf29c03e89);
        validatorSets[1][1] = address(0x00c33e5a769379a7f485a167e91e991121b0743b03);
        validatorSets[1][2] = address(0x008991ee92f51430014bc7498d947366d05b0f9cc3);
        validatorSets[1][3] = address(0x00d561fd65ee6c8ce3d4b7a93648c5aca312332be5);
        validatorSets[1][4] = address(0x00fd344788ffb1668535d88016ae554f1f83a0c796);

        // Realized volatility

        validatorSets[2] = new address[](5);
        validatorSets[2][0] = address(0x0033169619754376315c1471cab101e27fd6f8b04c);
        validatorSets[2][1] = address(0x00eec7fdaa55ab594b43e0fd2c2cbfca4db7fad514);
        validatorSets[2][2] = address(0x00833fa09fcde048fa09330135e7aa87dbda6e0ec1);
        validatorSets[2][3] = address(0x00e32920bc862d733e0c5a7c3829a3fc5b0aac5f90);
        validatorSets[2][4] = address(0x0061efabeabd9f0d4274786b1e8547335d733cbbe6);

        // Options

        validatorSets[3] = new address[](5);
        validatorSets[3][0] = address(0x00c33a6edb6cd4501cf5300dac7a40f88c89781634);
        validatorSets[3][1] = address(0x00434585d48bba02a80f5b72c028a34e5b641e71e8);
        validatorSets[3][2] = address(0x00172d9a1d5895ad34cda871a146a710345c5071bd);
        validatorSets[3][3] = address(0x000a8d40ca144dfc38d0773b4df85a38564608588d);
        validatorSets[3][4] = address(0x00fbcd35d30825b8155d6702d168b0c80bdb9bf84c);

        // Perp

        validatorSets[4] = new address[](5);
        validatorSets[4][0] = address(0x00e308fffa5d4928613c92b6b278401abb6a6a2782);
        validatorSets[4][1] = address(0x001a21a61ada1a896b2b4284eb0c10821baa5a1b92);
        validatorSets[4][2] = address(0x00de5d2ba26fab8a449867ee5b7542afa997f193c0);
        validatorSets[4][3] = address(0x0042c1f70436a51336f29baee67e1a62b0f7455b62);
        validatorSets[4][4] = address(0x0010d3948375ac01c5c4b24c0bcb279ef3acbff297);

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

    function testGasAllUpdates() public {
        string[5] memory updateTypes = ["SpotMedian", "TWAP", "RealizedVolatility", "Options", "Perpetuals"];
        string[5] memory currencies = ["ETH/USD", "BTC/USD", "ETH/USD", "ETH/USD", "ETH/USD"];
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
            pragmaDecoder.exposed_updateDataInfoFromUpdate(encodedUpdate);
            uint256 gasUsed = gasBefore - gasleft();

            console.log(string(abi.encodePacked("Gas used for ", updateTypes[i], " update: ", vm.toString(gasUsed))));
        }
    }
}
