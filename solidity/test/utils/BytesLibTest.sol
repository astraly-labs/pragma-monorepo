import "../../src/libraries/BytesLib.sol";
import "forge-std/Test.sol";

contract BytesToInt256Test is Test {
    function testPositiveNumber() public pure {
        bytes memory data = abi.encode(int256(123456789));
        assertEq(BytesLib.toInt256(data, 0), int256(123456789));
    }

    function testNegativeNumber() public pure {
        bytes memory data = abi.encode(int256(-987654321));
        assertEq(BytesLib.toInt256(data, 0), int256(-987654321));
    }

    function testZero() public pure {
        bytes memory data = abi.encode(int256(0));
        assertEq(BytesLib.toInt256(data, 0), int256(0));
    }

    function testMaxInt256() public pure {
        bytes memory data = abi.encode(type(int256).max);
        assertEq(BytesLib.toInt256(data, 0), type(int256).max);
    }

    function testMinInt256() public pure {
        bytes memory data = abi.encode(type(int256).min);
        assertEq(BytesLib.toInt256(data, 0), type(int256).min);
    }

    function testNonZeroStart() public pure {
        bytes memory data = abi.encode(uint256(1), int256(-1234));
        assertEq(BytesLib.toInt256(data, 32), int256(-1234));
    }

    function testOutOfBounds() public {
        bytes memory data = abi.encode(int256(1));
        vm.expectRevert("toInt256_outOfBounds");
        BytesLib.toInt256(data, 1);
    }

    function testSpecificFailingCase() public {
        int256 value = 1738;
        uint8 offset = 224;

        // Prevent overflow in memory allocation
        uint256 safeLength = uint256(offset) + 32;
        require(safeLength >= offset, "Overflow in length calculation");

        bytes memory data = new bytes(safeLength);

        console.log("Original value:", uint256(value));
        console.log("Offset:", offset);
        console.log("Data length:", data.length);

        assembly {
            mstore(add(add(data, 32), offset), value)
        }

        console.logBytes(data);

        int256 retrievedValue = BytesLib.toInt256(data, offset);

        console.log("Retrieved value:", uint256(retrievedValue));

        assertEq(retrievedValue, value, "Retrieved value does not match original value");
    }

    function testFuzzing(int256 value, uint8 offset) public {
        // Prevent overflow in memory allocation
        uint256 safeLength = uint256(offset) + 32;
        vm.assume(safeLength >= offset);

        bytes memory data = new bytes(safeLength);

        assembly {
            mstore(add(add(data, 32), offset), value)
        }

        int256 retrievedValue = BytesLib.toInt256(data, offset);

        if (retrievedValue != value) {
            console.log("Failing case:");
            console.log("Original value:", uint256(value));
            console.log("Retrieved value:", uint256(retrievedValue));
            console.log("Offset:", offset);
            console.logBytes(data);
        }

        assertEq(retrievedValue, value, "Retrieved value does not match original value");
    }
}