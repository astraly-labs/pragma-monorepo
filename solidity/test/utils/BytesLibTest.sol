import "../../src/libraries/BytesLib.sol";
import "forge-std/Test.sol";


contract BytesToInt256Test is Test {
   
    function testPositiveNumber() public pure {
        bytes memory data = abi.encode(int256(123456789));
        assertEq(BytesLib.toInt256(data, 0), int256(123456789));
    }

    function testNegativeNumber() public pure  {
        bytes memory data = abi.encode(int256(-987654321));
        assertEq(BytesLib.toInt256(data, 0), int256(-987654321));
    }

    function testZero() public pure  {
        bytes memory data = abi.encode(int256(0));
        assertEq(BytesLib.toInt256(data, 0), int256(0));
    }

    function testMaxInt256() public pure  {
        bytes memory data = abi.encode(type(int256).max);
        assertEq(BytesLib.toInt256(data, 0), type(int256).max);
    }

    function testMinInt256() public pure  {
        bytes memory data = abi.encode(type(int256).min);
        assertEq(BytesLib.toInt256(data, 0), type(int256).min);
    }

    function testNonZeroStart() public pure  {
        bytes memory data = abi.encode(uint256(1), int256(-1234));
        assertEq(BytesLib.toInt256(data, 32), int256(-1234));
    }

    function testOutOfBounds() public   {
        bytes memory data = abi.encode(int256(1));
        vm.expectRevert("toInt256_outOfBounds");
        BytesLib.toInt256(data, 1);
    }

    function testFuzzing(int256 value, uint8 offset) public pure  {
        vm.assume(offset <= 224);  // Ensure we have at least 32 bytes after the offset
        bytes memory data = new bytes(offset + 32);
        assembly {
            mstore(add(add(data, 32), offset), value)
        }
        assertEq(BytesLib.toInt256(data, offset), value);
    }
}