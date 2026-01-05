// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Taxpayer} from "../src/Taxpayer.sol";
import {Lottery} from "../src/Lottery.sol";

contract EchidnaTesting {
    Taxpayer[] taxpayers;
    mapping(address => uint256) wins;
    address lottery;
    uint256 total_ends;

    constructor() {
        addTaxpayer();
        addTaxpayer();
        addTaxpayer();
        addOldTaxpayer();
        addOldTaxpayer();

        // Initialize lottery immediately!
        Lottery l = new Lottery(0);
        lottery = address(l);
    }

    function addTaxpayer() internal {
        taxpayers.push(new Taxpayer(address(0), address(0), 28, 5, 2003));
    }

    function addOldTaxpayer() internal {
        taxpayers.push(new Taxpayer(address(0), address(0), 28, 5, 1950));
    }

    function create_lottery() external {
        require(lottery == address(0));
        Lottery l = new Lottery(0);
        lottery = address(l);
    }

    function endLottery() external {
        require(lottery != address(0));
        address winner = Lottery(lottery).endLottery();
        wins[winner] += 1;
        total_ends += 1;
        lottery = address(0);
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

    function getAddress(uint256 index) internal view returns (address) {
        return address(taxpayers[index]);
    }

    function getMaxWins() internal view returns (address maxAddress, uint256 maxValue) {
        maxAddress = address(0);
        maxValue = 0;
        for (uint256 index = 0; index < taxpayers.length; index++) {
            address t = getAddress(index);
            uint256 w = wins[t];
            if (w > maxValue) {
                maxValue = w;
                maxAddress = t;
            }
        }
    }

    function getMinWins() internal view returns (address minAddress, uint256 minValue) {
        minAddress = getAddress(0);
        minValue = wins[minAddress];
        for (uint256 index = 1; index < taxpayers.length; index++) {
            address t = getAddress(index);
            uint256 w = wins[t];
            if (w < minValue) {
                minValue = w;
                minAddress = t;
            }
        }
    }

    function echidna_check_lottery() public view returns (bool) {
        (address minAddress, uint256 minValue) = getMinWins();
        (address maxAddress, uint256 maxValue) = getMaxWins();

        if (wins[address(0)] > 0) return false;

        // Allow the lottery to run!
        // Only check the distribution statistics after enough data is collected.
        if (total_ends < 5) return true;

        // Check if the spread between winners is acceptable
        // Note: < 1 implies everyone has the EXACT same number of wins, which is statistically unlikely.
        // You might want a higher threshold like < 5 depending on the number of iterations.
        return (maxValue - minValue) < 2;
    }
}
