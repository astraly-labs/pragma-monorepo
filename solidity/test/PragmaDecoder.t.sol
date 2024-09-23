// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/PragmaDecoder.sol";
import "../src/libraries/DataParser.sol";
import "../src/interfaces/IHyperlane.sol";
import "../src/libraries/ErrorsLib.sol";
import "./../src/Hyperlane.sol";
import "../src/libraries/BytesLib.sol";
import {TestUtils} from "./TestUtils.sol";

contract PragmaDecoderHarness is PragmaDecoder {
    constructor(
        address _hyperlane,
        uint16[] memory _dataSourceEmitterChainIds,
        bytes32[] memory _dataSourceEmitterAddresses
    ) PragmaDecoder(_hyperlane, _dataSourceEmitterChainIds, _dataSourceEmitterAddresses) {}

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

contract PragmaDecoderTest is Test {
    PragmaDecoderHarness private pragmaDecoder;

    using BytesLib for bytes;

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

    function testUpdateDataInfoFromUpdateSpotMedian() public {
        _setUp(FeedType.SpotMedian);
        bytes32 feedId = bytes32(
            abi.encodePacked(
                uint16(0),
                ///CRYPTO
                uint8(0), //SPOT
                uint8(0), //VARIANT
                bytes32("ETH/USD")
            )
        );
        bytes memory encodedUpdate = TestUtils.createEncodedUpdate(FeedType.SpotMedian, feedId);
        uint8 numUpdates = pragmaDecoder.exposed_updateDataInfoFromUpdate(encodedUpdate);

        assertEq(numUpdates, 1, "Number of updates should be 1");

        SpotMedian memory spotMedian = pragmaDecoder.exposed_spotMedianFeeds(feedId);

        assertEq(spotMedian.metadata.timestamp, block.timestamp, "Timestamp should match");
        assertEq(spotMedian.metadata.numberOfSources, 5, "Number of sources should be 5");
        assertEq(spotMedian.metadata.decimals, 8, "Decimals should be 8");
        assertEq(spotMedian.metadata.feedId, feedId, "Feed ID should match");
        assertEq(spotMedian.price, 2000 * 1e8, "Price should match");
        assertEq(spotMedian.volume, 1000 * 1e18, "Volume should match");
    }

    function testUpdateDataInfoFromUpdateTWAP() public {
        _setUp(FeedType.Twap);
        bytes32 feedId = bytes32(
            abi.encodePacked(
                uint16(0),
                ///CRYPTO
                uint8(1), //TWAP
                uint8(0), // VARIANT
                bytes32("BTC/USD")
            )
        );
        bytes memory encodedUpdate = TestUtils.createEncodedUpdate(FeedType.Twap, feedId);
        uint8 numUpdates = pragmaDecoder.exposed_updateDataInfoFromUpdate(encodedUpdate);

        assertEq(numUpdates, 1, "Number of updates should be 1");

        TWAP memory twap = pragmaDecoder.exposed_twapFeeds(feedId);

        assertEq(twap.metadata.timestamp, block.timestamp, "Timestamp should match");
        assertEq(twap.metadata.numberOfSources, 5, "Number of sources should be 5");
        assertEq(twap.metadata.decimals, 8, "Decimals should be 8");
        assertEq(twap.metadata.feedId, feedId, "Feed ID should match");
        assertEq(twap.twapPrice, 30000 * 1e8, "TWAP price should match");
        assertEq(twap.timePeriod, 3600, "Time period should match");
        assertEq(twap.startPrice, 29000 * 1e8, "Start price should match");
        assertEq(twap.endPrice, 31000 * 1e8, "End price should match");
        assertEq(twap.totalVolume, 1000 * 1e18, "Total volume should match");
        assertEq(twap.numberOfDataPoints, 60, "Number of data points should match");
    }

    function testUpdateDataInfoFromUpdateRealizedVolatility() public {
        _setUp(FeedType.RealizedVolatility);
        bytes32 feedId = bytes32(
            abi.encodePacked(
                uint16(0),
                ///CRYPTO
                uint8(2), //RV
                uint8(0), //VARIANT
                bytes32("ETH/USD")
            )
        );
        bytes memory encodedUpdate = TestUtils.createEncodedUpdate(FeedType.RealizedVolatility, feedId);
        uint8 numUpdates = pragmaDecoder.exposed_updateDataInfoFromUpdate(encodedUpdate);
        RealizedVolatility memory rv = pragmaDecoder.exposed_rvFeeds(feedId);

        assertEq(numUpdates, 1, "Number of updates should be 1");
        assertEq(rv.metadata.timestamp, block.timestamp, "Timestamp should match");
        assertEq(rv.metadata.numberOfSources, 5, "Number of sources should be 5");
        assertEq(rv.metadata.decimals, 8, "Decimals should be 8");
        assertEq(rv.metadata.feedId, feedId, "Feed id ID should match");
        assertEq(rv.volatility, 50 * 1e6, "Volatility should match"); // 50% volatility
        assertEq(rv.timePeriod, 86400, "Time period should match");
        assertEq(rv.startPrice, 1900 * 1e8, "Start price should match");
        assertEq(rv.endPrice, 2100 * 1e8, "End price should match");
        assertEq(rv.high_price, 2200 * 1e8, "High price should match");
        assertEq(rv.low_price, 1800 * 1e8, "Low price should match");
        assertEq(rv.numberOfDataPoints, 1440, "Number of data points should match");
    }

    function testUpdateDataInfoFromUpdateOptions() public {
        _setUp(FeedType.Options);
        bytes32 feedId = bytes32(
            abi.encodePacked(
                uint16(0),
                ///CRYPTO
                uint8(3), //Options
                uint8(0),
                bytes32("ETH/USD")
            )
        );
        bytes memory encodedUpdate = TestUtils.createEncodedUpdate(FeedType.Options, feedId);
        uint8 numUpdates = pragmaDecoder.exposed_updateDataInfoFromUpdate(encodedUpdate);

        assertEq(numUpdates, 1, "Number of updates should be 1");

        Options memory options = pragmaDecoder.exposed_optionsFeeds(feedId);

        assertEq(options.metadata.timestamp, block.timestamp, "Timestamp should match");
        assertEq(options.metadata.numberOfSources, 5, "Number of sources should be 5");
        assertEq(options.metadata.decimals, 8, "Decimals should be 8");
        assertEq(options.metadata.feedId, feedId, "Feed ID should match");
        assertEq(options.strikePrice, 2000 * 1e8, "Strike price should match");
        assertEq(options.impliedVolatility, 50 * 1e6, "Implied volatility should match");
        assertEq(options.timeToExpiry, 604800, "Time to expiry should match");
        assertEq(options.isCall, true, "Option type should be call");
        assertEq(options.underlyingPrice, 1950 * 1e8, "Underlying price should match");
        assertEq(options.optionPrice, 100 * 1e8, "Option price should match");
        assertEq(options.delta, 60 * 1e6, "Delta should match");
        assertEq(options.gamma, 2 * 1e6, "Gamma should match");
        assertEq(options.vega, 10 * 1e6, "Vega should match");
        assertEq(options.theta, -5 * 1e6, "Theta should match");
        assertEq(options.rho, 3 * 1e6, "Rho should match");
    }

    function testUpdateDataInfoFromUpdatePerp() public {
        _setUp(FeedType.Perpetuals);
        bytes32 feedId = bytes32(
            abi.encodePacked(
                uint16(0),
                ///CRYPTO
                uint8(4), //Perp
                uint8(0), //VARIANT
                bytes32("ETH/USD")
            )
        );
        bytes memory encodedUpdate = TestUtils.createEncodedUpdate(FeedType.Perpetuals, feedId);
        uint8 numUpdates = pragmaDecoder.exposed_updateDataInfoFromUpdate(encodedUpdate);

        assertEq(numUpdates, 1, "Number of updates should be 1");
        Perp memory perp = pragmaDecoder.exposed_perpFeeds(feedId);

        assertEq(perp.metadata.timestamp, block.timestamp, "Timestamp should match");
        assertEq(perp.metadata.numberOfSources, 5, "Number of sources should be 5");
        assertEq(perp.metadata.decimals, 8, "Decimals should be 8");
        assertEq(perp.metadata.feedId, feedId, "Feed ID should match");
        assertEq(perp.markPrice, 2000 * 1e8, "Mark price should match");
        assertEq(perp.fundingRate, 1 * 1e6, "Funding rate should match"); // 0.1% funding rate
        assertEq(perp.openInterest, 10000 * 1e18, "Open interest should match");
        assertEq(perp.volume, 50000 * 1e18, "Volume should match");
    }
}
