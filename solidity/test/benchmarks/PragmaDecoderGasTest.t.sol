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

    function testGasAllUpdates() public {
        string[5] memory updateTypes = ["SpotMedian", "TWAP", "RealizedVolatility", "Options", "Perpetuals"];
        string[5] memory currencies = ["ETH/USD", "BTC/USD", "ETH/USD", "ETH/USD", "ETH/USD"];
        for (uint256 i = 0; i < updateTypes.length; i++) {
            FeedType dataType = FeedType(i);
            _setUp(dataType);

            bytes32 feedId = bytes32(
                abi.encodePacked(
                    uint16(0), // CRYPTO
                    uint16(i), // Data type index
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
