// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Taxpayer} from "../src/Taxpayer.sol";
import {Lottery} from "../src/Lottery.sol";
import "./FactoryTaxpayer.sol";

contract EchidnaTesting {
    FactoryTaxpayer f;
    Taxpayer[] taxpayers;

    constructor() {
        f = new FactoryTaxpayer(address(this));
        addTaxpayer();
        addTaxpayer();
        // addTaxpayer();
        // addTaxpayer();
        // addTaxpayer();
        // addOldTaxpayer();
        // addOldTaxpayer();
    }

    function addTaxpayer() internal {
        address t = f.createTaxpayer(address(0), address(0), 28, 5, 2003);
        taxpayers.push(Taxpayer(t));
    }

    function addOldTaxpayer() internal {
        address t = f.createTaxpayer(address(0), address(0), 28, 5, 1950);
        taxpayers.push(Taxpayer(t));
    }

    function check_spouse(uint256 index) internal view returns (bool) {
        Taxpayer t = taxpayers[index];
        if (t.isMarried()) {
            return Taxpayer(t.getSpouse()).getSpouse() == address(t) && t.getSpouse() != address(t);
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

    // function echidna_check_tax_allowance() public view returns (bool) {
    //     for (uint256 index = 0; index < taxpayers.length; index++) {
    //         if (!check_tax_allowance(index)) {
    //             return false;
    //         }
    //     }
    //     return true;
    // }

    function check_reedem_tax_allowance(uint256 index) public view returns (bool) {
        uint256 ALLOWANCE_OAP = 7000;
        uint256 DEFAULT_ALLOWANCE = 5000;

        Taxpayer t = taxpayers[index];
        if (t.isReedemed()) {
            if (t.isMarried()) {
                Taxpayer spouse = Taxpayer(t.getSpouse());
                uint256 spouseContribute = 0;
                if (spouse.isReedemed()) {
                    spouseContribute = ALLOWANCE_OAP;
                } else {
                    spouseContribute = DEFAULT_ALLOWANCE;
                }
                uint256 maxAllowance = t.getTaxAllowance() + spouse.getTaxAllowance();
                return maxAllowance == t.getMaxTaxAllowance() && maxAllowance == spouse.getMaxTaxAllowance()
                    && maxAllowance == (ALLOWANCE_OAP + spouseContribute);
            } else {
                return t.getTaxAllowance() == ALLOWANCE_OAP;
            }
        } else {
            if (t.isMarried()) {
                Taxpayer spouse = Taxpayer(t.getSpouse());
                uint256 spouseContribute = 0;
                if (spouse.isReedemed()) {
                    spouseContribute = ALLOWANCE_OAP;
                } else {
                    spouseContribute = DEFAULT_ALLOWANCE;
                }
                uint256 maxAllowance = t.getTaxAllowance() + spouse.getTaxAllowance();
                return maxAllowance == t.getMaxTaxAllowance() && maxAllowance == spouse.getMaxTaxAllowance()
                    && maxAllowance == (DEFAULT_ALLOWANCE + spouseContribute);
            } else {
                return t.getTaxAllowance() == DEFAULT_ALLOWANCE;
            }
        }
        return true;
    }

    function echidna_reedem_check(uint256 index) internal view returns (bool) {
        Taxpayer t = taxpayers[index];
        if (t.isReedemed()) {
            return t.age() >= 65;
        }
        return true;
    }

    function echidna_reedem() public view returns (bool) {
        for (uint256 index = 0; index < taxpayers.length; index++) {
            if (!echidna_reedem_check(index)) {
                return false;
            }
        }
        return true;
    }

    function echidna_reedem_taxAllowance() public view returns (bool) {
        for (uint256 index = 0; index < taxpayers.length; index++) {
            if (!check_reedem_tax_allowance(index)) {
                return false;
            }
        }
        return true;
    }

    function getAddress(uint256 index) internal view returns (address) {
        return address(taxpayers[index]);
    }
}
