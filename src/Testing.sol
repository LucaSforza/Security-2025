// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Taxpayer} from "../src/Taxpayer.sol";

contract EchidnaTesting {
    Taxpayer[] taxpayers;

    constructor() {
        addTaxpayer();
        addTaxpayer();
        addTaxpayer();
        addTaxpayer();
        addTaxpayer();
    }

    function addTaxpayer() internal {
        taxpayers.push(new Taxpayer(address(0), address(0), 1041379200));
    }

    function check_spouse(uint256 index) internal view returns (bool) {
        Taxpayer t = taxpayers[index];
        if (t.isMarried()) {
            return Taxpayer(t.getSpouse()).getSpouse() == address(t);
        }
        return true;
    }

    function check_tax_allowance(uint256 index) internal view returns (bool) {
        Taxpayer t = taxpayers[index];
        if (t.isMarried()) {
            Taxpayer spouse = Taxpayer(t.getSpouse());
            uint256 maxAllowance = t.getTaxAllowance() + spouse.getTaxAllowance();
            return maxAllowance == t.getMaxTaxAllowance() && maxAllowance == spouse.getMaxTaxAllowance();
        }
        return true;
    }

    function echidna_check_spouse() public view returns (bool) {
        for (uint256 index = 0; index < taxpayers.length; index++) {
            if (!check_spouse(index)) {
                return false;
            }
        }
        return true;
    }

    function echidna_check_tax_allowance() public view returns (bool) {
        for (uint256 index = 0; index < taxpayers.length; index++) {
            if (!check_tax_allowance(index)) {
                return false;
            }
        }
        return true;
    }
}
