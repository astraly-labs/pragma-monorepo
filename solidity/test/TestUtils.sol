// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/libraries/BytesLib.sol";
import "../src/interfaces/PragmaStructs.sol";
import "../src/interfaces/IHyperlane.sol";
import "./PragmaDecoder.t.sol";
import "../src/Hyperlane.sol";
import "../src/Pragma.sol";
import "./utils/TestConstants.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract PragmaHarness is Pragma {
    constructor() Pragma() {}

    function exposed_updateDataInfoFromUpdate(bytes calldata updateData) external returns (uint8) {
        return updateDataInfoFromUpdate(updateData);
    }

    function exposed_spotMedianFeeds(bytes32 feedId) external view returns (SpotMedian memory) {
        return spotMedianFeeds[feedId];
    }

    function exposed_twapFeeds(bytes32 feedId) external view returns (TWAP memory) {
        return twapFeeds[feedId];
    }

    function exposed_rvFeeds(bytes32 feedId) external view returns (RealizedVolatility memory) {
        return rvFeeds[feedId];
    }

    function exposed_optionsFeeds(bytes32 feedId) external view returns (Options memory) {
        return optionsFeeds[feedId];
    }

    function exposed_perpFeeds(bytes32 feedId) external view returns (Perp memory) {
        return perpFeeds[feedId];
    }

    function _isProofValid(bytes calldata encodedProof, uint256 offset, bytes32 root, bytes calldata leafData)
        internal
        virtual
        override
        returns (bool valid, uint256 endOffset)
    {
        // valid set to true for testing
        unchecked {
            bytes32 currentDigest = MerkleTree.leafHash(leafData);
            uint256 proofOffset = 0;
            uint16 proofSizeArray = UnsafeCalldataBytesLib.toUint16(encodedProof, proofOffset);
            proofOffset += 2;
            for (uint256 i = 0; i < proofSizeArray; i++) {
                bytes32 siblingDigest = bytes32(UnsafeCalldataBytesLib.toBytes32(encodedProof, proofOffset));
                proofOffset += 32; // TO CHECK

                currentDigest = MerkleTree.nodeHash(currentDigest, siblingDigest);
            }
            valid = true;
            endOffset = offset + proofOffset;
        }
    }
}

library TestUtils {
    using BytesLib for bytes;

    function createHyperlaneMessage(bytes memory payload, bytes32 feedId) internal view returns (bytes memory) {
        bytes memory signatures = abi.encodePacked(
            uint8(5), // number of signatures
            uint8(0),
            bytes32(0x83db08d4e1590714aef8600f5f1e3c967ab6a3b9f93bb4242de0306510e688ea),
            bytes32(0x0af5d1d51ea7e51a291789ff4866a1e36bc4134d956870799380d2d71f5dbf3d),
            uint8(27),
            uint8(1),
            bytes32(0xf81a5dd3f871ad2d27a3b538e73663d723f8263fb3d289514346d43d000175f5),
            bytes32(0x083df770623e9ae52a7bb154473961e24664bb003bdfdba6100fb5e540875ce1),
            uint8(27),
            uint8(2),
            bytes32(0x76b194f951f94492ca582dab63dc413b9ac1ca9992c22bc2186439e9ab8fdd3c),
            bytes32(0x62a6a6f402edaa53e9bdc715070a61edb0d98d4e14e182f60bdd4ae932b40b29),
            uint8(27),
            uint8(3),
            bytes32(0x35932eefd85897d868aaacd4ba7aee81a2384e42ba062133f6d37fdfebf94ad4),
            bytes32(0x78cce49db96ee27c3f461800388ac95101476605baa64a194b7dd4d56d2d4a4d),
            uint8(27),
            uint8(4),
            bytes32(0x6b38d4353d69396e91c57542254348d16459d448ab887574e9476a6ff76d49a1),
            bytes32(0x3527627295bde423d7d799afef22affac4f00c70a5b651ad14c8879aeb9b6e03),
            uint8(27)
        );

        return abi.encodePacked(
            TestConstantsLib.HYPERLANE_VERSION,
            signatures,
            uint32(0), // nonce
            uint64(block.timestamp), // timestamp
            uint32(1), // emitterChainId
            bytes32(uint256(0x1234)), // emitterAddress
            bytes32(uint256(0x12311)), // merkle tree hook address
            payload
        );
    }

    function createEncodedUpdate(FeedType dataType, bytes32 feedId) internal view returns (bytes memory) {
        bytes memory updateData = abi.encodePacked(
            feedId,
            uint64(block.timestamp), // timestamp
            uint16(5), // numberOfSources
            uint8(8) // decimals
        );
        if (dataType == FeedType.SpotMedian) {
            updateData = abi.encodePacked(
                updateData,
                uint256(2000 * 1e8), // price
                uint256(1000 * 1e18) // volume
            );
        } else if (dataType == FeedType.Twap) {
            updateData = abi.encodePacked(
                updateData,
                uint256(30000 * 1e8), // twapPrice
                uint256(3600), // timePeriod
                uint256(29000 * 1e8), // startPrice
                uint256(31000 * 1e8), // endPrice
                uint256(1000 * 1e18), // totalVolume
                uint256(60) // numberOfDataPoints
            );
        } else if (dataType == FeedType.RealizedVolatility) {
            updateData = abi.encodePacked(
                updateData,
                uint256(50 * 1e6), // volatility
                uint256(86400), // timePeriod
                uint256(1900 * 1e8), // startPrice
                uint256(2100 * 1e8), // endPrice
                uint256(2200 * 1e8), // highPrice
                uint256(1800 * 1e8), // lowPrice
                uint256(1440) // numberOfDataPoints
            );
        } else if (dataType == FeedType.Options) {
            updateData = abi.encodePacked(
                updateData,
                uint256(2000 * 1e8), // strikePrice
                uint256(50 * 1e6), // impliedVolatility
                uint256(604800), // timeToExpiry
                true, // isCall
                uint256(1950 * 1e8), // underlyingPrice
                uint256(100 * 1e8), // optionPrice
                uint256(60 * 1e6), // delta
                uint256(2 * 1e6), // gamma
                uint256(10 * 1e6), // vega
                int256(-5 * 1e6), // theta
                uint256(3 * 1e6) // rho
            );
        } else if (dataType == FeedType.Perpetuals) {
            updateData = abi.encodePacked(
                updateData,
                uint256(2000 * 1e8), // markPrice
                uint256(1 * 1e6), // fundingRate
                uint256(10000 * 1e18), // openInterest
                uint256(50000 * 1e18) // volume
            );
        }

        bytes memory proof = abi.encodePacked(
            uint16(3), // proof length in array
            bytes32(0x1012312123213123213231231233421341341234134142341123331123123123),
            bytes32(0x1012312312312312312311231233434342421414123413413123331123123123),
            bytes32(0x1012312312312312312312323324234234234234324234212123331123123123)
        );

        bytes memory hyMsgPayload = abi.encodePacked(
            keccak256(abi.encodePacked(feedId)), // root, arbitrary value to make sure hash are different
            uint32(1211), // checkpoint index
            bytes32(uint256(0x654)), // message id,
            uint8(1), // numUpdates
            uint16(updateData.length), // updateSize
            uint16(proof.length),
            proof,
            updateData,
            feedId, // feedId
            uint64(block.timestamp) // publishTime
        );

        bytes memory hyMsg = createHyperlaneMessage(hyMsgPayload, feedId);

        return abi.encodePacked(
            TestConstantsLib.MAJOR_VERSION,
            TestConstantsLib.MINOR_VERSION,
            TestConstantsLib.TRAILING_HEADER_SIZE,
            uint16(hyMsg.length), // hyMsgSize
            hyMsg
        );
    }

    function extractUpdateData(bytes memory encodedUpdate) internal pure returns (bytes memory) {
        // Skip the header (22 bytes) and extract the update data
        return encodedUpdate.slice(22, encodedUpdate.length - 22);
    }

    function setUpHyperlane(uint8 numValidators, address[] memory initSigners) public returns (address) {
        if (initSigners.length == 0) {
            initSigners = new address[](numValidators);
        }
        Hyperlane hyperlane_ = new Hyperlane(initSigners);
        return address(hyperlane_);
    }

    function configurePragmaContract(FeedType dataType) internal returns (address) {
        address[][] memory validatorSets = new address[][](5);
        // SPOT MEDIAN

        validatorSets[0] = new address[](5);
        validatorSets[0][0] = address(0x00e8E7139138f65b1aa54DA6947acD517209D3f394);
        validatorSets[0][1] = address(0x008c28701CFc840C250E254E4fC39FB91CCC6AA8D7);
        validatorSets[0][2] = address(0x00f15acc7Cb78888c5D9428B1522425c204e4ABAd5);
        validatorSets[0][3] = address(0x00CeCc9Bc7f72DE019579F6e1a5fb969CBbb2A7bd5);
        validatorSets[0][4] = address(0x00Fa992B3954C23e1b8882Ac32d964374E06F55333);

        // TWAP

        validatorSets[1] = new address[](5);
        validatorSets[1][0] = address(0x00e3b5D43D7f26E4bDa6f6B26cB170C176f0dA5a20);
        validatorSets[1][1] = address(0x0098E4Ba0098C45880d5Fbb60E9B0b9e07168FBd61);
        validatorSets[1][2] = address(0x00585EF8DE363ed6d6c0CaD3787fD6E0a17719EA0B);
        validatorSets[1][3] = address(0x00976Ae456b0C4B2F98719dfB47237e27e69375748);
        validatorSets[1][4] = address(0x001597E2726DDd04eeaF091BC23f5e46D8558dDcA6);

        // Realized volatility

        validatorSets[2] = new address[](5);
        validatorSets[2][0] = address(0x00d9607ED6086BEE33C572C05B1B7cB645caCf8dD3);
        validatorSets[2][1] = address(0x00FeC1E22DEC7D064bEBB88692ddaEaCDeA6Eb593f);
        validatorSets[2][2] = address(0x000Af1cbA0Ce31d2A9B6BeC4b8700caA26B0cCeCE9);
        validatorSets[2][3] = address(0x009F85b89b07C9b8E607886b9f6C068a6b14E2e3f0);
        validatorSets[2][4] = address(0x003A5B961D0Be9e10BA79b6249C2e05F88bcD2c51b);

        // Options

        validatorSets[3] = new address[](5);
        validatorSets[3][0] = address(0x00e86C32850c1d9426B03668f351F831082d2E4044);
        validatorSets[3][1] = address(0x005d79EBF4fE933b3086b1Eb0d8Fc82aF10511a9f1);
        validatorSets[3][2] = address(0x006A403FD4dAf647Be863839b3f767a85736dA031e);
        validatorSets[3][3] = address(0x000c10AEB13fCc0dCb40AD130aa02102DF011f7731);
        validatorSets[3][4] = address(0x00B434aA8CA372c496242015CC4215ca10dEFA6dC2);

        // Perp
        validatorSets[4] = new address[](5);
        validatorSets[4][0] = address(0x0074C61a875653D6cD07c6aFD8499625f4248c32b4);
        validatorSets[4][1] = address(0x00b8E79066654F5cb18CDC0610dA40a57a962d6253);
        validatorSets[4][2] = address(0x0071fA97365539079cEe27DC1De110277B400f1151);
        validatorSets[4][3] = address(0x00fB065ded62A92D7BEb7Ed0cCEB717808227Fe9A9);
        validatorSets[4][4] = address(0x008841cF99b6b607e898B59E7674E05f794701535C);

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

        uint32[] memory chainIds = new uint32[](1);
        chainIds[0] = 1;

        bytes32[] memory emitterAddresses = new bytes32[](1);
        emitterAddresses[0] = bytes32(uint256(0x1234));

        PragmaHarness pragmaImpl = new PragmaHarness();

        bytes memory initData = abi.encodeWithSelector(
            pragmaImpl.initialize.selector,
            address(hyperlane),
            address(this),
            chainIds,
            emitterAddresses,
            120,
            0.1 ether
        );

        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(pragmaImpl), address(this), initData);
        return address(proxy);
    }

    // This function reproduce a real evm configuration for testing purposes
    function setupRealEnvironment() internal returns (address) {
        address[] memory validatorSets = new address[](1);
        validatorSets[0] = address(0xF6311461A6d8b44cb3F62b2FCd47570A28443ca0);
        IHyperlane hyperlane = IHyperlane(setUpHyperlane(uint8(validatorSets.length), validatorSets));
        uint32[] memory chainIds = new uint32[](1);
        chainIds[0] = 6363709;

        bytes32[] memory emitterAddresses = new bytes32[](1);
        emitterAddresses[0] = bytes32(uint256(0x60240F2BCCEF7E64F920EEC05C5BFFFBC48C6CEAA4EFCA8748772B60CBAFC3));

        PragmaHarness pragmaImpl = new PragmaHarness();

        bytes memory initData = abi.encodeWithSelector(
            pragmaImpl.initialize.selector,
            address(hyperlane),
            address(this),
            chainIds,
            emitterAddresses,
            120,
            0.1 ether
        );

        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(pragmaImpl), address(this), initData);
        return address(proxy);
    }
}
