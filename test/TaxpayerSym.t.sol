// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {FactoryTaxpayer} from "../src/FactoryTaxpayer.sol";
import {Taxpayer} from "../src/Taxpayer.sol";

contract TaxpayerSym is Test {
    uint256 constant START_TIME = 1_760_000_000;
    uint256 constant DEFAULT_ALLOWANCE = 5000;
    uint256 constant ALLOWANCE_OAP = 7000;

    enum Action { NOP, Marry, Divorce, Redeem, TransferAllowance }

    FactoryTaxpayer factory;
    Taxpayer[4] taxpayers;

    function setUp() public {
        vm.warp(START_TIME);
        factory = new FactoryTaxpayer(address(this));

        address t0 = factory.createTaxpayer(address(0), address(0), 28, 5, 2003);
        address t1 = factory.createTaxpayer(address(0), address(0), 28, 5, 2003);
        address t2 = factory.createTaxpayer(address(0), address(0), 28, 5, 1950);
        address t3 = factory.createTaxpayer(address(0), address(0), 28, 5, 1950);

        taxpayers[0] = Taxpayer(payable(t0));
        taxpayers[1] = Taxpayer(payable(t1));
        taxpayers[2] = Taxpayer(payable(t2));
        taxpayers[3] = Taxpayer(payable(t3));
    }

    /// @dev Symbolic action sequence + invariant checks
    function check_taxpayer_invariants(
        uint8[5] memory acts,
        uint256[5] memory actors,
        uint256[5] memory spouses,
        uint256[5] memory amounts
    ) public {
        // Validate action types upfront
        for (uint256 i = 0; i < 5; i++) {
            vm.assume(acts[i] <= uint8(Action.TransferAllowance));
        }

        // Dispatch action sequence
        for (uint256 i = 0; i < 5; i++) {
            if (acts[i] == uint8(Action.Marry)) {
                vm.assume(actors[i] < 4 && spouses[i] < 4);
                vm.assume(actors[i] != spouses[i]);
                vm.assume(!taxpayers[actors[i]].isMarried());
                vm.assume(!taxpayers[spouses[i]].isMarried());
                taxpayers[actors[i]].marry(address(taxpayers[spouses[i]]));
            } else if (acts[i] == uint8(Action.Divorce)) {
                vm.assume(actors[i] < 4);
                vm.assume(taxpayers[actors[i]].isMarried());
                taxpayers[actors[i]].divorce();
            } else if (acts[i] == uint8(Action.Redeem)) {
                vm.assume(actors[i] < 4);
                vm.assume(taxpayers[actors[i]].age() >= 65);
                vm.assume(!taxpayers[actors[i]].isReedemed());
                taxpayers[actors[i]].redeemTaxAllowance();
            } else if (acts[i] == uint8(Action.TransferAllowance)) {
                vm.assume(actors[i] < 4);
                vm.assume(taxpayers[actors[i]].isMarried());
                vm.assume(amounts[i] <= taxpayers[actors[i]].getTaxAllowance());
                taxpayers[actors[i]].transferAllowance(amounts[i]);
            }
            // NOP: skip
        }

        // Invariant 1: Spouse reciprocity
        for (uint256 i = 0; i < 4; i++) {
            if (taxpayers[i].isMarried()) {
                address spouse = taxpayers[i].getSpouse();
                assert(spouse != address(0));
                assert(spouse != address(taxpayers[i]));
                assert(Taxpayer(spouse).getSpouse() == address(taxpayers[i]));
            }
        }

        // Invariant 2: Redeem age gate — only age >= 65 can have redeemed
        for (uint256 i = 0; i < 4; i++) {
            if (taxpayers[i].isReedemed()) {
                assert(taxpayers[i].age() >= 65);
            }
        }

        // Invariant 3: Allowance sum conservation for married couples
        for (uint256 i = 0; i < 4; i++) {
            if (taxpayers[i].isMarried()) {
                address spouse = taxpayers[i].getSpouse();
                uint256 sum = taxpayers[i].getTaxAllowance() + Taxpayer(spouse).getTaxAllowance();
                assert(sum == taxpayers[i].getMaxTaxAllowance());
            }
        }
    }
}
