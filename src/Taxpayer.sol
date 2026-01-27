// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Lottery, ILottery} from "./Lottery.sol";

import {IERC165} from "forge-std/interfaces/IERC165.sol";

import {ERC165Query} from "./ERC165Query.sol";

import "./BokkyPooBahsDateTimeLibrary.sol";

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

using BokkyPooBahsDateTimeLibrary for uint256;

interface ILotteryReceiver {
    function joinLottery(address lot, uint256 r) external;
    function revealLottery() external;
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

    function redeemTaxAllowance() external nonReentrant {
        require(!redeemed && ITaxpayer(address(this)).age() >= AGE_THREASHOLD);
        redeemed = true;
        taxAllowance += (ALLOWANCE_OAP - DEFAULT_ALLOWANCE);
        if (isMarried()) {
            marriage.maxAllowance += (ALLOWANCE_OAP - DEFAULT_ALLOWANCE);
            ITaxpayer(ITaxpayer(address(this)).getSpouse())
                .redeemTaxAllowanceOfSpouse(ALLOWANCE_OAP - DEFAULT_ALLOWANCE);
        }
    }

    function redeemTaxAllowanceOfSpouse(uint256 value) external {
        require(ITaxpayer(address(this)).getSpouse() == msg.sender, "the caller must be the spouse");
        marriage.maxAllowance += value; // (ALLOWANCE_OAP - DEFAULT_ALLOWANCE);
    }

    function getMaxTaxAllowance() external view returns (uint256 maxAllowance) {
        if (isMarried()) {
            maxAllowance = marriage.maxAllowance;
        } else {
            maxAllowance = 0;
        }
    }
    // bool iscontract; changed Can we do better using ERC-165

    address public immutable parent1; // changed in to public
    address public immutable parent2;

    /* Income tax allowance */
    uint256 private taxAllowance;

    uint256 public income; // changed to public

    uint256 private rev; // changed must be private

    //Parents are taxpayers
    constructor(address p1, address p2, uint8 day, uint8 month, uint16 year) {
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
        birthday = BirthDate(year, month, day);
        parent1 = p1;
        parent2 = p2;
        marriage.spouse = address(0);
        income = 0;
        redeemed = false;
        taxAllowance = DEFAULT_ALLOWANCE;
        wins = 0;
    }

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        if (interfaceId == 0xffffffff) {
            return false;
        }
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(ITaxpayer).interfaceId
            || interfaceId == type(ILotteryReceiver).interfaceId;
    }

    modifier checkInterfaceTaxpayer(address a) {
        require(doesContractImplementInterface(a, type(ITaxpayer).interfaceId), "Spouse not Taxpayer");
        _; // Body of the function
    }

    modifier checkInterfaceLottery(address a) {
        require(doesContractImplementInterface(a, type(ILottery).interfaceId), "Lottery not Taxpayer");
        _; // Body of the function
    }

    event Message(string);

    function _assert(bool condition, string memory message) internal {
        if (!condition) {
            emit Message(message);
            emit AssertionFailed(1);
        }
    }
    event AssertionFailed(uint256);

    //We require newSpouse != address(0);
    function marry(address newSpouse) public nonReentrant checkInterfaceTaxpayer(newSpouse) {
        require(newSpouse != address(0));
        require(!isMarried(), "Already married");
        require(newSpouse != address(this), "Cannot marry self");

        require(doesContractImplementInterface(newSpouse, type(ITaxpayer).interfaceId), "must marry a Taxpayer");

        marriage.spouse = newSpouse;
        marriage.maxAllowance = this.getTaxAllowance() + ITaxpayer(newSpouse).getTaxAllowance();

        ITaxpayer(newSpouse).acceptMarriage(address(this));
    }

    function acceptMarriage(address newSpouse) external nonReentrant checkInterfaceTaxpayer(newSpouse) {
        require(msg.sender == newSpouse, "Caller must be the spouse");
        require(!isMarried(), "Already married");
        require(doesContractImplementInterface(newSpouse, type(ITaxpayer).interfaceId), "must marry a Taxpayer");

        marriage.spouse = newSpouse;
        marriage.maxAllowance = this.getTaxAllowance() + ITaxpayer(newSpouse).getTaxAllowance();
        _assert(ITaxpayer(newSpouse).getSpouse() == address(this), "the new spouse is not me");
        _assert(ITaxpayer(newSpouse).getMaxTaxAllowance() == marriage.maxAllowance, "max Allowance is not consistent");
    }

    function divorce() public nonReentrant {
        require(isMarried(), "must have a spouse");
        address oldSpouse = marriage.spouse;
        marriage.spouse = address(0); // non serve mettere maxTaxAllowance a zero. Più gas efficient
        if (this.isReedemed()) taxAllowance = ALLOWANCE_OAP;
        else taxAllowance = DEFAULT_ALLOWANCE;
        taxAllowance += 2000 * wins;
        ITaxpayer(oldSpouse).acceptDivorce();
        _assert(ITaxpayer(oldSpouse).getSpouse() == address(0), "the spouse must be zero");
        _assert(
            !ITaxpayer(oldSpouse).isReedemed()
                || ITaxpayer(oldSpouse).getTaxAllowance() == ALLOWANCE_OAP + ITaxpayer(oldSpouse).getWins() * 2000,
            string.concat(
                "old spouse is reedemed, but the tax allowance is: ",
                Strings.toString(ITaxpayer(oldSpouse).getTaxAllowance())
            )
        );
        _assert(
            ITaxpayer(oldSpouse).isReedemed()
                || ITaxpayer(oldSpouse).getTaxAllowance() == DEFAULT_ALLOWANCE + ITaxpayer(oldSpouse).getWins() * 2000,
            string.concat(
                "old spouse is not reedemed, but the tax allowance is: ",
                Strings.toString(ITaxpayer(oldSpouse).getTaxAllowance())
            )
        );
    }

    function acceptDivorce() public nonReentrant {
        require(marriage.spouse == msg.sender);
        if (this.isReedemed()) taxAllowance = ALLOWANCE_OAP;
        else taxAllowance = DEFAULT_ALLOWANCE;
        taxAllowance += 2000 * wins;
        // It is not required to check that the spouse implement ITaxpayer interface, we assumed so beacuse we have checked
        // it that the spouse implement this interface when we marry them TODO: dire meglio
        // require(doesContractImplementInterface(oldSpouse, type(ITaxpayer).interfaceId), "Spouse not Taxpayer");
        marriage.spouse = address(0);
    }

    /* Transfer part of tax allowance to own spouse */
    function transferAllowance(uint256 change) public {
        require(isMarried(), "you must be married to transfer allowance");
        require(taxAllowance >= change, "cannot change more than the taxAllowance holded");
        taxAllowance = taxAllowance - change;
        ITaxpayer sp = ITaxpayer(address(marriage.spouse));
        sp.setTaxAllowance(sp.getTaxAllowance() + change);
        _assert(
            sp.getTaxAllowance() + this.getTaxAllowance() == marriage.maxAllowance,
            "max allowance is not consistent to sum of tax allowances"
        );
        _assert(sp.getMaxTaxAllowance() == marriage.maxAllowance, "max allowance is not consistent in cached value");
    }

    function age() public view returns (uint256) {
        uint256 ts = block.timestamp;
        BirthDate memory birth = birthday;

        uint256 currentYear = ts.getYear();
        uint256 currentMonth = ts.getMonth();
        uint256 currentDay = ts.getDay();

        uint256 age = currentYear - birth.year;

        if (currentMonth < birth.month || (currentMonth == birth.month && currentDay < birth.day)) {
            age -= 1;
        }

        return age;
    }

    // TODO: Dire nella relazione che queste pre-condizioni devono essere vero
    function setTaxAllowance(uint256 ta)
        public
        nonReentrant
        checkInterfaceTaxpayer(msg.sender)
        checkInterfaceLottery(msg.sender)
    {
        // require(Taxpayer(msg.sender).isContract() || Lottery(msg.sender).isContract());
        // This pre-condition is wrong. Use ERC-165 instead
        taxAllowance = ta;
    }

    /* function isContract() public view returns (bool) {
        return iscontract;
    } it is useless if we are using ERC-165 */

    function getTaxAllowance() external view returns (uint256 allowance) {
        return taxAllowance;
    }

    address joinedLottery;

    function joinLottery(address lot, uint256 r) public {
        // What if we joing more than one lottery?
        require(rev == 0, "cannot join more than one lottery");
        require(doesContractImplementInterface(lot, type(ILottery).interfaceId), "lot is not a lottery");
        Lottery l = Lottery(lot);
        l.commit(keccak256(abi.encode(r)));
        rev = r;
        joinedLottery = lot;
    }

    function revealLottery() public {
        Lottery l = Lottery(joinedLottery);
        l.reveal(rev);
        rev = 0; // TODO: dire nella relazione che questo parametro non è sicuro, dato che qualsiasi persona può leggere l'attributo rev anche se è private
        // ma per motivi di testing è stato lasciato, ma in production va levato.
    }

    uint256 wins;

    function winLottery() external {
        require(msg.sender == joinedLottery);
        taxAllowance += 2000;
        wins += 1;
        joinedLottery = address(0);
        if (isMarried()) {
            marriage.maxAllowance += 2000; // (ALLOWANCE_OAP - DEFAULT_ALLOWANCE);
            ITaxpayer(ITaxpayer(address(this)).getSpouse()).redeemTaxAllowanceOfSpouse(2000);
        }
    }

    function getWins() external returns (uint256) {
        return wins;
    }
}
