// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {FactoryTaxpayer} from "../src/FactoryTaxpayer.sol";
import {Taxpayer} from "../src/Taxpayer.sol";

contract TaxpayerHandler is Test {
    uint256 constant START_TIME = 1_760_000_000;
    uint256 constant DEFAULT_ALLOWANCE = 5000;
    uint256 constant ALLOWANCE_OAP = 7000;

    FactoryTaxpayer factory;
    Taxpayer[] taxpayers;

    constructor() {
        vm.warp(START_TIME);
        factory = new FactoryTaxpayer(address(this));
        for (uint256 i = 0; i < 5; i++) {
            address t = factory.createTaxpayer(address(0), address(0), 28, 5, 2003);
            taxpayers.push(Taxpayer(t));
        }
        for (uint256 i = 0; i < 2; i++) {
            address t = factory.createTaxpayer(address(0), address(0), 28, 5, 1950);
            taxpayers.push(Taxpayer(t));
        }
    }

    function marry(uint256 i, uint256 j) public {
        i = bound(i, 0, taxpayers.length - 1);
        j = bound(j, 0, taxpayers.length - 1);
        vm.assume(i != j);
        vm.assume(!taxpayers[i].isMarried());
        vm.assume(!taxpayers[j].isMarried());
        taxpayers[i].marry(address(taxpayers[j]));
    }

    function divorce(uint256 i) public {
        i = bound(i, 0, taxpayers.length - 1);
        vm.assume(taxpayers[i].isMarried());
        taxpayers[i].divorce();
    }

    function redeem(uint256 i) public {
        i = bound(i, 0, taxpayers.length - 1);
        vm.assume(!taxpayers[i].isReedemed());
        vm.assume(taxpayers[i].age() >= 65);
        taxpayers[i].redeemTaxAllowance();
    }

    function transferAllowance(uint256 i, uint256 amount) public {
        i = bound(i, 0, taxpayers.length - 1);
        vm.assume(taxpayers[i].isMarried());
        amount = bound(amount, 0, taxpayers[i].getTaxAllowance());
        taxpayers[i].transferAllowance(amount);
    }

    function taxpayersLength() public view returns (uint256) {
        return taxpayers.length;
    }

    function checkSpouse(uint256 i) public view returns (bool) {
        Taxpayer t = taxpayers[i];
        if (t.isMarried()) {
            return Taxpayer(t.getSpouse()).getSpouse() == address(t)
                && t.getSpouse() != address(t);
        }
        return true;
    }

    function checkRedeemAge(uint256 i) public view returns (bool) {
        Taxpayer t = taxpayers[i];
        if (t.isReedemed()) {
            return t.age() >= 65;
        }
        return true;
    }

    function checkTaxAllowance(uint256 i) public view returns (bool) {
        Taxpayer t = taxpayers[i];
        if (t.isReedemed()) {
            if (t.isMarried()) {
                Taxpayer spouse = Taxpayer(t.getSpouse());
                uint256 sc = spouse.isReedemed() ? ALLOWANCE_OAP : DEFAULT_ALLOWANCE;
                uint256 sum = t.getTaxAllowance() + spouse.getTaxAllowance();
                return sum == t.getMaxTaxAllowance()
                    && sum == spouse.getMaxTaxAllowance()
                    && sum == (ALLOWANCE_OAP + sc);
            } else {
                return t.getTaxAllowance() == ALLOWANCE_OAP;
            }
        } else {
            if (t.isMarried()) {
                Taxpayer spouse = Taxpayer(t.getSpouse());
                uint256 sc = spouse.isReedemed() ? ALLOWANCE_OAP : DEFAULT_ALLOWANCE;
                uint256 sum = t.getTaxAllowance() + spouse.getTaxAllowance();
                return sum == t.getMaxTaxAllowance()
                    && sum == spouse.getMaxTaxAllowance()
                    && sum == (DEFAULT_ALLOWANCE + sc);
            } else {
                return t.getTaxAllowance() == DEFAULT_ALLOWANCE;
            }
        }
    }
}

contract TaxpayerTest is Test {
    TaxpayerHandler handler;

    function setUp() public {
        handler = new TaxpayerHandler();
        targetContract(address(handler));
    }

    function invariant_spouse_symmetry() public {
        for (uint256 i = 0; i < handler.taxpayersLength(); i++) {
            assertTrue(handler.checkSpouse(i));
        }
    }

    function invariant_redeem_age() public {
        for (uint256 i = 0; i < handler.taxpayersLength(); i++) {
            assertTrue(handler.checkRedeemAge(i));
        }
    }

    function invariant_tax_allowance() public {
        for (uint256 i = 0; i < handler.taxpayersLength(); i++) {
            assertTrue(handler.checkTaxAllowance(i));
        }
    }
}
