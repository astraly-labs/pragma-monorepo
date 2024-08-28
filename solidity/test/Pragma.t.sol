// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IPragma} from "../src/interfaces/IPragma.sol";
import "./utils/PragmaTestUtils.t.sol";

contract PragmaTest is Test, PragmaTestUtils {
    IPragma public pragma_;

    uint8 constant NUM_VALIDATORS = 10;

    function setUp() public {
        // TODO: setup hyperlane
        pragma_ = IPragma(setUpPragma(address(0)));
    }
}
