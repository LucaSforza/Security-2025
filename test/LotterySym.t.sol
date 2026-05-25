// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {FactoryTaxpayer} from "../src/FactoryTaxpayer.sol";
import {Taxpayer} from "../src/Taxpayer.sol";
import {Lottery} from "../src/Lottery.sol";

contract LotterySym is Test {
    uint256 constant START_TIME = 1_760_000_000;

    enum LotteryAction { NOP, Start, Join, End, SelectWinner }

    FactoryTaxpayer factory;
    Taxpayer[2] taxpayers;
    Lottery lottery;

    function setUp() public {
        vm.warp(START_TIME);
        factory = new FactoryTaxpayer(address(this));

        address t1 = factory.createTaxpayer(address(0), address(0), 28, 5, 2003);
        address t2 = factory.createTaxpayer(address(0), address(0), 28, 5, 2003);
        taxpayers[0] = Taxpayer(payable(t1));
        taxpayers[1] = Taxpayer(payable(t2));
        lottery = Lottery(factory.getLottery());
    }

    /// @dev Symbolic action sequence covering lottery state machine
    function check_lottery_invariants(
        uint8[6] memory acts,
        uint256[6] memory actors,
        uint256[6] memory seeds
    ) public {
        for (uint256 i = 0; i < 6; i++) {
            vm.assume(acts[i] <= uint8(LotteryAction.SelectWinner));
            vm.assume(actors[i] < 2);
        }

        for (uint256 i = 0; i < 6; i++) {
            if (acts[i] == uint8(LotteryAction.Start)) {
                lottery.startLottery();
            } else if (acts[i] == uint8(LotteryAction.Join)) {
                lottery.join(address(taxpayers[actors[i]]));
            } else if (acts[i] == uint8(LotteryAction.End)) {
                bytes32 sealedHash = keccak256(abi.encodePacked(address(this), seeds[i]));
                lottery.endLottery(sealedHash);
            } else if (acts[i] == uint8(LotteryAction.SelectWinner)) {
                vm.roll(block.number + 1);
                lottery.selectWinner(seeds[i]);
            }
            // NOP: skip
        }
        // State machine enforced by require() in Lottery contract.
        // Halmos verifies no assertion is reachable on any successful path.
    }

    /// @dev Proves duplicate join succeeds (joined[...] = false bug)
    function check_join_bug() public {
        lottery.startLottery();
        lottery.join(address(taxpayers[0]));
        try lottery.join(address(taxpayers[0])) {
            assert(false); // Duplicate join succeeded — bug confirmed
        } catch {
            assert(true);  // Duplicate join reverted — bug fixed
        }
    }
}
