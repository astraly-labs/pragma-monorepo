// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/libraries/BytesLib.sol";
import "../src/interfaces/PragmaStructs.sol";
import "../src/interfaces/IHyperlane.sol";
import "./PragmaDecoder.t.sol";
import "../src/Hyperlane.sol";
import "../src/Pragma.sol";
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

    function createHyperlaneMessage(bytes memory payload) internal view returns (bytes memory) {
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
            uint8(1), // version
            signatures,
            uint32(0), // nonce
            uint64(block.timestamp), // timestamp
            uint32(1), // emitterChainId
            bytes32(uint256(0x1234)), // emitterAddress
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
            bytes32(uint256(1)), // checkpointRoot
            uint8(1), // numUpdates
            uint16(updateData.length), // updateSize
            uint16(proof.length),
            proof,
            updateData,
            feedId, // feedId
            uint64(block.timestamp) // publishTime
        );

        bytes memory hyMsg = createHyperlaneMessage(hyMsgPayload);

        return abi.encodePacked(
            uint8(1), // majorVersion
            uint8(0), // minorVersion
            uint8(0), // trailingHeaderSize
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
        validatorSets[0][0] = address(0x005fed8c9ac5f77b556502f23d3f081d85cd0ef7d3);
        validatorSets[0][1] = address(0x00c59779fbbd88dcd3f406355f7e35a3b9a8441903);
        validatorSets[0][2] = address(0x00e86a95ee11bdd5f55e87c3d994ec07f45cb37af1);
        validatorSets[0][3] = address(0x00b2f7780f23b8e55171435bf1ea42a785c65e3593);
        validatorSets[0][4] = address(0x00229160af0c289b6e1d4d5663e734ad9c512dd42e);

        // TWAP

        validatorSets[1] = new address[](5);
        validatorSets[1][0] = address(0x000016318e65c08ca34446460b31af1ca63a9c4792);
        validatorSets[1][1] = address(0x004b09f8e943f3eb69e1b638ed6aa82a7749ad3254);
        validatorSets[1][2] = address(0x001e814f589de93b09f63127d00030681712fc4353);
        validatorSets[1][3] = address(0x00253e4fb18b8461531ac9b2e3bb74a7120398ab0c);
        validatorSets[1][4] = address(0x0062db22a1ed74d5fd52e18568a2508ad55f3b3684);

        // Realized volatility

        validatorSets[2] = new address[](5);
        validatorSets[2][0] = address(0x0092b2198616ddaacebb75b722ed06488be0eaad70);
        validatorSets[2][1] = address(0x00f0e06e9085f5503382eaab574c0b10ed7af14328);
        validatorSets[2][2] = address(0x006eb5cc46f6ee7b2ba5721ad552de04961f7d8914);
        validatorSets[2][3] = address(0x001ac77837845ce1e904d38f15fb32b9a05db51372);
        validatorSets[2][4] = address(0x00167c3a23c3858c22dfe6638d86e0eeab0642e5de);

        // Options

        validatorSets[3] = new address[](5);
        validatorSets[3][0] = address(0x000f7e97b9adee19e9b167ebfbd2e411da215152f8);
        validatorSets[3][1] = address(0x00d9f9d3c74c6724312445924daf819d26eeaf46d2);
        validatorSets[3][2] = address(0x00832097796157409a8ef055a4b2aedc67464fa0d3);
        validatorSets[3][3] = address(0x003ca43df1b8b8d3fdf37720e10317894179393c5a);
        validatorSets[3][4] = address(0x00babda821efa81b802c12eefab0719e6e1f567f06);

        // Perp
        validatorSets[4] = new address[](5);
        validatorSets[4][0] = address(0x0074f0bc628d146702c2341ee5ef3fb04dbfb9c94e);
        validatorSets[4][1] = address(0x001b3948765c201e333dc038ef6f4c952b8f1a2983);
        validatorSets[4][2] = address(0x00f4701da46a1aa29f0dcdebc803d8a7d66987093d);
        validatorSets[4][3] = address(0x007eefff669d7bad40b10acdbdfdf202c9cf27e710);
        validatorSets[4][4] = address(0x00dbc7c81f7045359e4b43c8ca0d41a8396b66337a);

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
}
