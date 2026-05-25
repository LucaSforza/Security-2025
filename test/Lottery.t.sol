// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {FactoryTaxpayer} from "../src/FactoryTaxpayer.sol";
import {Taxpayer} from "../src/Taxpayer.sol";
import {Lottery} from "../src/Lottery.sol";

contract LotteryHandler is Test {
    uint256 constant START_TIME = 1_760_000_000;

    FactoryTaxpayer factory;
    Taxpayer[] taxpayers;
    Lottery lottery;
    mapping(address => uint256) wins;
    uint256 totalEnds;

    constructor() {
        vm.warp(START_TIME);
        factory = new FactoryTaxpayer(address(this));
        for (uint256 i = 0; i < 5; i++) {
            address t = factory.createTaxpayer(address(0), address(0), 28, 5, 2003);
            taxpayers.push(Taxpayer(t));
        }
        lottery = Lottery(factory.getLottery());
    }

    function completeIteration(uint256 seed) public {
        lottery.startLottery();
        for (uint256 i = 0; i < taxpayers.length; i++) {
            taxpayers[i].joinLottery();
        }
        bytes32 sealedSeed = keccak256(abi.encodePacked(address(this), seed));
        lottery.endLottery(sealedSeed);
        vm.roll(block.number + 1);

        try lottery.selectWinner(seed) returns (address winner) {
            wins[winner]++;
            totalEnds++;
        } catch {
            // Expected reverts: not in Ending state, bad seed reveal, etc.
        }
    }

    function getMaxWins() public view returns (address maxAddr, uint256 maxVal) {
        maxAddr = address(0);
        maxVal = 0;
        for (uint256 i = 0; i < taxpayers.length; i++) {
            address t = address(taxpayers[i]);
            uint256 w = wins[t];
            if (w > maxVal) {
                maxVal = w;
                maxAddr = t;
            }
        }
    }

    function getMinWins() public view returns (address minAddr, uint256 minVal) {
        minAddr = address(0);
        minVal = wins[minAddr];
        for (uint256 i = 1; i < taxpayers.length; i++) {
            address t = address(taxpayers[i]);
            uint256 w = wins[t];
            if (w < minVal) {
                minVal = w;
                minAddr = t;
            }
        }
    }

    function getTotalEnds() public view returns (uint256) {
        return totalEnds;
    }

    function getWins(address addr) public view returns (uint256) {
        return wins[addr];
    }
}

contract LotteryTest is Test {
    LotteryHandler handler;

    function setUp() public {
        handler = new LotteryHandler();
        targetContract(address(handler));
    }

    function invariant_lottery_fairness() public {
        assertEq(handler.getWins(address(0)), 0, "zero address won");
        if (handler.getTotalEnds() >= 5) {
            (address minAddr, uint256 minVal) = handler.getMinWins();
            (address maxAddr, uint256 maxVal) = handler.getMaxWins();
            assertTrue(maxVal - minVal < 25, "win spread too large");
        }
    }
}
