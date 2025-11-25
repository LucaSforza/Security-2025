// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Lottery} from "./Lottery.sol";

contract Taxpayer {
    uint256 age; // This is wrong! a taxpayer should increment his age every birthday manually
        // This can add a lot of costs beacuse updating this attribute need GAS to be updated.

    bool isMarried;

    bool iscontract; // Can we do better using ERC-162

    /* Reference to spouse if person is married, address(0) otherwise */
    address spouse; // How check that the spouse is married to us?

    address parent1;
    address parent2;

    /* Constant default income tax allowance */
    uint256 constant DEFAULT_ALLOWANCE = 5000;

    /* Constant income tax allowance for Older Taxpayers over 65 */
    uint256 constant ALLOWANCE_OAP = 7000;

    /* Income tax allowance */
    uint256 taxAllowance;

    uint256 income;

    uint256 rev;

    //Parents are taxpayers
    constructor(address p1, address p2) {
        age = 0;
        isMarried = false;
        parent1 = p1;
        parent2 = p2;
        spouse = address(0);
        income = 0;
        taxAllowance = DEFAULT_ALLOWANCE;
        iscontract = true;
    }

    //We require newSpouse != address(0);
    function marry(address newSpouse) public {
        spouse = newSpouse;
        isMarried = true;
    }

    function divorce() public {
        spouse = address(0);
        isMarried = false;
    }

    /* Transfer part of tax allowance to own spouse */
    function transferAllowance(uint256 change) public {
        taxAllowance = taxAllowance - change;
        Taxpayer sp = Taxpayer(address(spouse));
        sp.setTaxAllowance(sp.getTaxAllowance() + change);
    }

    function haveBirthday() public {
        age++;
    }

    function setTaxAllowance(uint256 ta) public {
        require(Taxpayer(msg.sender).isContract() || Lottery(msg.sender).isContract());
        taxAllowance = ta;
    }

    function getTaxAllowance() public view returns (uint256) {
        return taxAllowance;
    }

    function isContract() public view returns (bool) {
        return iscontract;
    }

    function joinLottery(address lot, uint256 r) public {
        // What if we joing more than one lottery?
        Lottery l = Lottery(lot);
        l.commit(keccak256(abi.encode(r)));
        rev = r;
    }

    function revealLottery(address lot, uint256 r) public {
        Lottery l = Lottery(lot);
        l.reveal(r);
        rev = 0;
    }
}
