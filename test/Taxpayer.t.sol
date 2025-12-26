// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Taxpayer} from "../src/Taxpayer.sol";

contract LotteryTest is Test {
    Taxpayer public taxpayer;

    function setUp() public {
        // taxpayer = new Taxpayer(address(0), address(0), block.timestamp);
    }
}
