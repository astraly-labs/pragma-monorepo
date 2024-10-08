// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract RandTestUtils is Test {
    uint256 randSeed;

    function setRandSeed(uint256 seed) internal {
        randSeed = seed;
    }

    function getRandBytes32() internal returns (bytes32) {
        unchecked {
            randSeed++;
        }
        return keccak256(abi.encode(randSeed));
    }

    function getRandUint() internal returns (uint256) {
        return uint256(getRandBytes32());
    }

    function getRandUint64() internal returns (uint64) {
        return uint64(getRandUint());
    }

    function getRandInt64() internal returns (int64) {
        return int64(getRandUint64());
    }

    function getRandUint32() internal returns (uint32) {
        return uint32(getRandUint());
    }

    function getRandInt32() internal returns (int32) {
        return int32(getRandUint32());
    }

    function getRandUint8() internal returns (uint8) {
        return uint8(getRandUint());
    }

    function getRandInt8() internal returns (int8) {
        return int8(getRandUint8());
    }
}
