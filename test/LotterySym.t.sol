// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {FactoryTaxpayer} from "../src/FactoryTaxpayer.sol";
import {Taxpayer} from "../src/Taxpayer.sol";
import {Lottery} from "../src/Lottery.sol";

contract LotterySym is Test {
    uint256 constant START_TIME = 1_760_000_000;

    FactoryTaxpayer factory;
    Taxpayer taxpayer;
    Taxpayer taxpayer2;
    Lottery lottery;

    function setUp() public {
        vm.warp(START_TIME);
        factory = new FactoryTaxpayer(address(this));

        address t1 = factory.createTaxpayer(address(0), address(0), 28, 5, 2003);
        address t2 = factory.createTaxpayer(address(0), address(0), 28, 5, 2003);
        taxpayer = Taxpayer(payable(t1));
        taxpayer2 = Taxpayer(payable(t2));
        lottery = Lottery(factory.getLottery());
    }

    // L1: Start lottery from NotStarted -> join succeeds
    function check_state_not_started_allows_start() public {
        lottery.startLottery();
        lottery.join(address(taxpayer));
    }

    // L2: Full round -> winner is registered player
    function check_state_started_allows_join() public {
        lottery.startLottery();
        lottery.join(address(taxpayer));

        bytes32 sealedHash = keccak256(abi.encodePacked(address(this), uint256(1)));
        lottery.endLottery(sealedHash);
        vm.roll(block.number + 1);

        address winner = lottery.selectWinner(1);
        assert(winner == address(taxpayer));
    }

    // L3: Detect join() bug where joined[...] = false instead of true
    function check_join_bug_duplicate_entry() public {
        lottery.startLottery();
        lottery.join(address(taxpayer));

        // Under the bug: second join succeeds because joined flag stays false
        // Under a fix: second join reverts with "already joined"
        try lottery.join(address(taxpayer)) {
            // Second join succeeded -> bug is present
            assert(false);
        } catch {
            assert(true);
        }
    }

    // L4: endLottery in NotStarted state must revert
    function check_state_transition_invalid_reverts() public {
        try lottery.endLottery(keccak256("x")) {
            assert(false);
        } catch {
            assert(true);
        }
    }

    // L5: Wrong seed in selectWinner must revert (commit-reveal mismatch)
    function check_wrong_seed_reverts() public {
        uint256 realSeed = 42;
        bytes32 sealedSeed = keccak256(abi.encodePacked(address(this), realSeed));

        lottery.startLottery();
        lottery.join(address(taxpayer));
        lottery.endLottery(sealedSeed);
        vm.roll(block.number + 1);

        // Use wrong seed -> keccak256(owner, wrong) != sealedSeed
        try lottery.selectWinner(uint256(keccak256("wrong"))) {
            assert(false);
        } catch {
            assert(true);
        }
    }

    // L6: Correct seed -> selectWinner succeeds
    function check_right_seed_succeeds() public {
        uint256 realSeed = 42;
        bytes32 sealedSeed = keccak256(abi.encodePacked(address(this), realSeed));

        lottery.startLottery();
        lottery.join(address(taxpayer));
        lottery.endLottery(sealedSeed);
        vm.roll(block.number + 1);

        address winner = lottery.selectWinner(realSeed);
        assert(winner == address(taxpayer));
    }
}
