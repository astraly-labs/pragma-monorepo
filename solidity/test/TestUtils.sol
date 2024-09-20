// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/libraries/BytesLib.sol";
import "../src/interfaces/PragmaStructs.sol";

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
            uint16(1), // emitterChainId
            bytes32(uint256(0x1234)), // emitterAddress
            payload
        );
    }

    function createEncodedUpdate(FeedType dataType, bytes32 feedId) internal view returns (bytes memory) {
        bytes memory updateData = abi.encodePacked(
            feedId,
            uint32(block.timestamp), // timestamp
            uint16(5), // numberOfSources
            uint8(8) // decimals
        );
        if (dataType == FeedType.SpotMedian) {
            updateData = abi.encodePacked(
                updateData,
                uint128(2000 * 1e8), // price
                uint128(1000 * 1e18) // volume
            );
        } else if (dataType == FeedType.Twap) {
            updateData = abi.encodePacked(
                updateData,
                uint128(30000 * 1e8), // twapPrice
                uint128(3600), // timePeriod
                uint128(29000 * 1e8), // startPrice
                uint128(31000 * 1e8), // endPrice
                uint128(1000 * 1e18), // totalVolume
                uint128(60) // numberOfDataPoints
            );
        } else if (dataType == FeedType.RealizedVolatility) {
            updateData = abi.encodePacked(
                updateData,
                uint128(50 * 1e6), // volatility
                uint128(86400), // timePeriod
                uint128(1900 * 1e8), // startPrice
                uint128(2100 * 1e8), // endPrice
                uint128(2200 * 1e8), // highPrice
                uint128(1800 * 1e8), // lowPrice
                uint128(1440) // numberOfDataPoints
            );
        } else if (dataType == FeedType.Options) {
            updateData = abi.encodePacked(
                updateData,
                uint128(2000 * 1e8), // strikePrice
                uint128(50 * 1e6), // impliedVolatility
                uint64(604800), // timeToExpiry
                true, // isCall
                uint128(1950 * 1e8), // underlyingPrice
                uint128(100 * 1e8), // optionPrice
                int256(60 * 1e6), // delta
                int256(2 * 1e6), // gamma
                int256(10 * 1e6), // vega
                int256(-5 * 1e6), // theta
                int256(3 * 1e6) // rho
            );
        } else if (dataType == FeedType.Perpetuals) {
            updateData = abi.encodePacked(
                updateData,
                uint128(2000 * 1e8), // markPrice
                uint128(1 * 1e6), // fundingRate
                uint128(10000 * 1e18), // openInterest
                uint128(50000 * 1e18) // volume
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
}
