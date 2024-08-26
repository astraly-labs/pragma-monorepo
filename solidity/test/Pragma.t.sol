// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Pragma} from "../src/Pragma.sol";

contract PragmaT is Test {
    Pragma public pragma_;

    function setUp() public {
        // pragma_ = new Pragma();
    }
}
