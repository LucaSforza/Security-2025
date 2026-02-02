// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Lottery} from "../src/Lottery.sol";

contract LotteryScript is Script {
    Lottery public lottery;

    function setUp() public {}

    function run() public {
        // vm.startBroadcast();
        //
        // lottery = new Lottery(10);
        //
        // vm.stopBroadcast();
    }
}
