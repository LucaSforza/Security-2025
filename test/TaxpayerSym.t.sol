// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {FactoryTaxpayer} from "../src/FactoryTaxpayer.sol";
import {Taxpayer} from "../src/Taxpayer.sol";

contract TaxpayerSym is Test {
    uint256 constant START_TIME = 1_760_000_000;
    uint256 constant DEFAULT_ALLOWANCE = 5000;
    uint256 constant ALLOWANCE_OAP = 7000;

    FactoryTaxpayer factory;
    Taxpayer youngA;
    Taxpayer youngB;
    Taxpayer oldA;
    Taxpayer oldB;

    function setUp() public {
        vm.warp(START_TIME);
        factory = new FactoryTaxpayer(address(this));

        address t0 = factory.createTaxpayer(address(0), address(0), 28, 5, 2003);
        address t1 = factory.createTaxpayer(address(0), address(0), 28, 5, 2003);
        address t2 = factory.createTaxpayer(address(0), address(0), 28, 5, 1950);
        address t3 = factory.createTaxpayer(address(0), address(0), 28, 5, 1950);

        youngA = Taxpayer(payable(t0));
        youngB = Taxpayer(payable(t1));
        oldA = Taxpayer(payable(t2));
        oldB = Taxpayer(payable(t3));
    }

    // C1: Marry -> spouse pointers reciprocal
    function check_marry_spouse_reciprocity() public {
        youngA.marry(address(youngB));

        assert(youngA.isMarried());
        assert(youngB.isMarried());
        assert(youngA.getSpouse() == address(youngB));
        assert(youngB.getSpouse() == address(youngA));
    }

    // C2: After marriage sum of allowances == maxAllowance on both sides
    function check_marry_allowance_conservation() public {
        youngA.marry(address(youngB));

        uint256 sum = youngA.getTaxAllowance() + youngB.getTaxAllowance();
        assert(sum == youngA.getMaxTaxAllowance());
        assert(sum == youngB.getMaxTaxAllowance());
    }

    // C3: Transfer preserves allowance sum (symbolic amount)
    function check_transfer_allowance_conservation(uint256 amount) public {
        youngA.marry(address(youngB));

        vm.assume(amount <= youngA.getTaxAllowance());

        youngA.transferAllowance(amount);

        uint256 sum = youngA.getTaxAllowance() + youngB.getTaxAllowance();
        assert(sum == youngA.getMaxTaxAllowance());
        assert(sum == youngB.getMaxTaxAllowance());
    }

    // C4: Old taxpayer (age >= 65) can redeem -> allowance becomes ALLOWANCE_OAP
    function check_redeem_age_gate_succeeds() public {
        vm.assume(oldA.age() >= 65);
        vm.assume(!oldA.isReedemed());

        oldA.redeemTaxAllowance();

        assert(oldA.isReedemed());
        assert(oldA.getTaxAllowance() == ALLOWANCE_OAP);
    }

    // C5: Young taxpayer (age < 65) cannot redeem -> must revert
    function check_redeem_age_gate_young_reverts() public {
        vm.assume(youngA.age() < 65);
        vm.assume(!youngA.isReedemed());

        try youngA.redeemTaxAllowance() {
            assert(false);
        } catch {
            assert(true);
        }
    }

    // C6: Marry old+young then redeem old -> allowance + maxAllowance synced
    function check_redeem_spouse_sync() public {
        oldA.marry(address(youngB));

        vm.assume(oldA.age() >= 65);
        vm.assume(!oldA.isReedemed());

        oldA.redeemTaxAllowance();

        uint256 expectedSum = DEFAULT_ALLOWANCE + ALLOWANCE_OAP;
        uint256 sum = oldA.getTaxAllowance() + youngB.getTaxAllowance();
        assert(sum == expectedSum);
        assert(sum == oldA.getMaxTaxAllowance());
        assert(sum == youngB.getMaxTaxAllowance());
    }

    // C7: Divorce clears both spouses to address(0)
    function check_divorce_clears_spouse() public {
        youngA.marry(address(youngB));

        assert(youngA.isMarried());
        assert(youngB.isMarried());

        youngA.divorce();

        assert(!youngA.isMarried());
        assert(!youngB.isMarried());
        assert(youngA.getSpouse() == address(0));
        assert(youngB.getSpouse() == address(0));
    }

    // C8: Divorce resets allowance to DEFAULT_ALLOWANCE
    function check_divorce_allowance_reset() public {
        youngA.marry(address(youngB));
        youngA.transferAllowance(2000);

        youngA.divorce();

        assert(youngA.getTaxAllowance() == DEFAULT_ALLOWANCE);
        assert(youngB.getTaxAllowance() == DEFAULT_ALLOWANCE);
    }
}
