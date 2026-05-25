// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Lottery, ILottery} from "./Lottery.sol";

import {IERC165} from "forge-std/interfaces/IERC165.sol";

import {ERC165Query} from "./ERC165Query.sol";

import "./BokkyPooBahsDateTimeLibrary.sol";

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

import "./FactoryTaxpayer.sol";

using BokkyPooBahsDateTimeLibrary for uint256;

interface ILotteryReceiver {
    function joinLottery() external;
    function winLottery() external;
    function getWins() external returns (uint256);
}

interface ITaxpayer is ILotteryReceiver, IERC165 {
    function marry(address newSpouse) external;
    function acceptMarriage(address newSpouse) external;
    function acceptDivorce() external;
    function divorce() external;
    function isMarried() external view returns (bool);
    function getSpouse() external view returns (address);
    function transferAllowance(uint256 change) external;
    function age() external view returns (uint256 _age);
    function setTaxAllowance(uint256 ta) external;
    function getTaxAllowance() external view returns (uint256 allowance);
    function getMaxTaxAllowance() external view returns (uint256 maxAllowance);
    function redeemTaxAllowance() external;
    function redeemTaxAllowanceOfSpouse(uint256 value) external;
    function isReedemed() external view returns (bool);
}

contract Taxpayer is ITaxpayer, ERC165Query, ReentrancyGuard {
    // uint256 age; This is wrong! a taxpayer should increment his age every birthday manually
    // This can add a lot of costs beacuse updating this attribute need GAS to be updated.

    FactoryTaxpayer immutable f;

    modifier isValid(address a) {
        // require(doesContractImplementInterface(a, type(ITaxpayer).interfaceId), "Spouse not Taxpayer");
        require(f.isTaxpayer(a) || f.isLottery(a));
        _; // Body of the function
    }

    struct Marriage {
        address spouse;
        uint256 maxAllowance;
    } // TODO: document

    struct BirthDate {
        uint16 year;
        uint8 month;
        uint8 day;
    }

    BirthDate public birthday; // changed created attribute public

    /* Reference to spouse if person is married, address(0) otherwise */
    Marriage public marriage;

    function getSpouse() external view returns (address) {
        return marriage.spouse;
    }

    /* Constant default income tax allowance */
    uint256 public constant DEFAULT_ALLOWANCE = 5000;

    /* Constant income tax allowance for Older Taxpayers over 65 */
    uint256 public constant ALLOWANCE_OAP = 7000;

    uint256 public constant AGE_THREASHOLD = 65;

    // bool public isMarried; changed in to a function, more GAS efficient
    function isMarried() public view returns (bool) {
        return marriage.spouse != address(0);
    }

    bool private redeemed;

    function isReedemed() external view returns (bool) {
        return redeemed;
    }

    function redeemTaxAllowance() external {
        require(!this.isReedemed() && ITaxpayer(address(this)).age() >= AGE_THREASHOLD);
    }

    function redeemTaxAllowanceOfSpouse(uint256 value) external {
        require(ITaxpayer(address(this)).getSpouse() == msg.sender, "the caller must be the spouse");
    }

    function getMaxTaxAllowance() external view returns (uint256 maxAllowance) {
    }
    // bool iscontract; changed Can we do better using ERC-165

    address public immutable parent1; // changed in to public
    address public immutable parent2;

    //Parents are taxpayers
    constructor(FactoryTaxpayer factory, address p1, address p2, uint8 day, uint8 month, uint16 year) {
        // changed new constructor argument and pre-cond/ition to check if the birthday is consistent
        // changed pre-condition about the interface of parents
        require(month > 0 && month <= 12);
        require(day > 0 && day <= 31);
        if (p1 != address(0)) {
            require(doesContractImplementInterface(p1, type(ITaxpayer).interfaceId), "parent1 is not a Taxpayer");
        }
        if (p2 != address(0)) {
            require(doesContractImplementInterface(p2, type(ITaxpayer).interfaceId), "parent2 is not a Taxpayer");
        }
    }

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        if (interfaceId == 0xffffffff) {
            return false;
        }
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(ITaxpayer).interfaceId
            || interfaceId == type(ILotteryReceiver).interfaceId;
    }

    //We require newSpouse != address(0);
    function marry(address newSpouse) public isValid(newSpouse) {
        require(newSpouse != address(0));
        require(!isMarried(), "Already married");
        require(newSpouse != address(this), "Cannot marry self");
        require(f.isTaxpayer(newSpouse), "the new spouse is not a registered taxpayer");
        require(doesContractImplementInterface(newSpouse, type(ITaxpayer).interfaceId), "must marry a Taxpayer");
    }

    function acceptMarriage(address newSpouse) external isValid(newSpouse) {
        require(msg.sender == newSpouse, "Caller must be the spouse");
        require(!isMarried(), "Already married");
        require(doesContractImplementInterface(newSpouse, type(ITaxpayer).interfaceId), "must marry a Taxpayer");

        assert(ITaxpayer(newSpouse).getSpouse() == address(this), "the new spouse is not me");
        assert(ITaxpayer(newSpouse).getMaxTaxAllowance() == marriage.maxAllowance, "max Allowance is not consistent");
    }

    function divorce() public {
        require(isMarried(), "must have a spouse");
        assert(ITaxpayer(oldSpouse).getSpouse() == address(0), "the spouse must be zero");
        assert(
            !ITaxpayer(oldSpouse).isReedemed()
                || ITaxpayer(oldSpouse).getTaxAllowance() == ALLOWANCE_OAP + ITaxpayer(oldSpouse).getWins() * 2000,
            string.concat(
                "old spouse is reedemed, but the tax allowance is: ",
                Strings.toString(ITaxpayer(oldSpouse).getTaxAllowance())
            )
        );
        assert(
            ITaxpayer(oldSpouse).isReedemed()
                || ITaxpayer(oldSpouse).getTaxAllowance() == DEFAULT_ALLOWANCE + ITaxpayer(oldSpouse).getWins() * 2000,
            string.concat(
                "old spouse is not reedemed, but the tax allowance is: ",
                Strings.toString(ITaxpayer(oldSpouse).getTaxAllowance())
            )
        );
    }

    function acceptDivorce() public {
        require(marriage.spouse == msg.sender);
    }

    /* Transfer part of tax allowance to own spouse */
    function transferAllowance(uint256 change) public {
        require(isMarried(), "you must be married to transfer allowance");
        require(taxAllowance >= change, "cannot change more than the taxAllowance holded");

        assert(
            sp.getTaxAllowance() + this.getTaxAllowance() == marriage.maxAllowance,
            "max allowance is not consistent to sum of tax allowances"
        );
        assert(sp.getMaxTaxAllowance() == marriage.maxAllowance, "max allowance is not consistent in cached value");
    }

    function age() public view returns (uint256) {
    }

    // TODO: Dire nella relazione che queste pre-condizioni devono essere vero
    function setTaxAllowance(uint256 ta) public isValid(msg.sender) {
        taxAllowance = ta;
    }

    function getTaxAllowance() external view returns (uint256 allowance) {
        return taxAllowance;
    }

    function joinLottery() public {
    }

    uint256 private wins;

    function winLottery() external {
        require(msg.sender == f.getLottery());
    }

    function getWins() external returns (uint256) {
        return wins;
    }
}
