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
           validatorSets[0][0] = address(0x003e54a28fc45e851dae5531dbfa9227fc28900f7b);
        validatorSets[0][1] = address(0x00c5e8c364734b105269d172c698ce8b6b229bd9ec);
        validatorSets[0][2] = address(0x007c98088d01b31e555fecd71c51ee6d9ef9805664);
        validatorSets[0][3] = address(0x00b38bdce02e6a241b319d9ad4afb417bc06048e64);
        validatorSets[0][4] = address(0x00f05e546f8e66d734e37b3386e51469b805708f55);

        // TWAP
        validatorSets[1] = new address[](5);
        validatorSets[1][0] = address(0x0048a9191faf3166dad193de597a498b38db71ad69);
        validatorSets[1][1] = address(0x00b0aedc451bda3541a13fc28ef101ca4766c03656);
        validatorSets[1][2] = address(0x0033a77751572bc3cd9aae829d40fdc68f86f693c0);
        validatorSets[1][3] = address(0x0040f89e3a65f1371d6e0b5bf439bce518cf0a7294);
        validatorSets[1][4] = address(0x00856f9cc1eb544db9f16df8c9a3127357b5c6da72);

        // Realized volatility
        validatorSets[2] = new address[](5);
        validatorSets[2][0] = address(0x004f5779ccd322560c8f6efc459a15c6568d4e0131);
        validatorSets[2][1] = address(0x00b3b27866ce8e55c5bfde6a97f489fe21399131e3);
        validatorSets[2][2] = address(0x00aa8397493450ba98e74d6b91eb9090c0e4470e2c);
        validatorSets[2][3] = address(0x007d02f8c4fd9f91cd38d9bddc90aa951a2d075feb);
        validatorSets[2][4] = address(0x00c1a0c130b377fe31bbb87fcde85e31a394469ff3);
        // Options

        validatorSets[3] = new address[](5);
        validatorSets[3][0] = address(0x0092a564bfea4aaed01154c4af87e926e94ff1553f);
        validatorSets[3][1] = address(0x00b7b0caaa443f350a656ac07afd11baee59e7f9a4);
        validatorSets[3][2] = address(0x00caec00ec76648d16c53ab48d30404b73e29160fe);
        validatorSets[3][3] = address(0x003d6fc1b256633ed56449fc4c6b7c540e05c92db6);
        validatorSets[3][4] = address(0x002171efbf40292383a75cb0c83010df944ee8a791);

        // Perp
        validatorSets[4] = new address[](5);
        validatorSets[4][0] = address(0x001494db521160e4852e1522229f07677e98a4c924);
        validatorSets[4][1] = address(0x009c1a235af2616036ecc8ae6d1a2fee2ae7752e65);
        validatorSets[4][2] = address(0x005d5267f7913b5b843e0df18624a950f331fb116d);
        validatorSets[4][3] = address(0x00404c2f0ee3c8b7f5992b006069a0e425184829ce);
        validatorSets[4][4] = address(0x00a98acbb77469b387975be4e9f381a50df54c8434);

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
