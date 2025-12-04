// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Taxpayer} from "../src/Taxpayer.sol";

contract TaxpayerEchidna is Taxpayer {
    constructor()
        Taxpayer(
            0x0000000000000000000000000000000000000000, 
            0x0000000000000000000000000000000000000000, 
            1041379200                              
        )
    {}
    
    // Invariante Echidna
    function echidna_check_spouse() public view returns (bool) {
        if(Taxpayer(this).getSpouse() != address(0)) {
            return Taxpayer(Taxpayer(this).getSpouse()).getSpouse() == address(this);
        }
        return true;
    }
}