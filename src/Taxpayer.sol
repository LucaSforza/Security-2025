// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Lottery, ILottery} from "./Lottery.sol";

import {IERC165} from "forge-std/interfaces/IERC165.sol";

import {ERC165Query} from "./ERC165Query.sol";

import "./BokkyPooBahsDateTimeLibrary.sol";

using BokkyPooBahsDateTimeLibrary for uint256;

interface ILotteryReceiver {
    function joinLottery(address lot, uint256 r) external;
    function revealLottery() external;
    function winLottery() external;
}

interface ITaxpayer is ILotteryReceiver, IERC165 {
    function marry(address newSpouse) external;
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
}

contract Taxpayer is ITaxpayer, ERC165Query {
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

    function redeemTaxAllowance() external {
        if (!redeemed && ITaxpayer(address(this)).age() >= AGE_THREASHOLD) {
            redeemed = true;
            taxAllowance += (ALLOWANCE_OAP - DEFAULT_ALLOWANCE);
            if (isMarried()) {
                marriage.maxAllowance += (ALLOWANCE_OAP - DEFAULT_ALLOWANCE);
                ITaxpayer(ITaxpayer(address(this)).getSpouse())
                    .redeemTaxAllowanceOfSpouse(ALLOWANCE_OAP - DEFAULT_ALLOWANCE);
            }
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
        // changed new constructor argument and pre-condition to check if the birthday is consistent
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
    }

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        if (interfaceId == 0xffffffff) {
            return false;
        }
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(ITaxpayer).interfaceId
            || interfaceId == type(ILotteryReceiver).interfaceId;
    }

    //We require newSpouse != address(0);
    function marry(address newSpouse) public {
        require(newSpouse != address(0));
        if (!isMarried()) {
            require(newSpouse != address(this));
            require(
                doesContractImplementInterface(newSpouse, type(ITaxpayer).interfaceId), "the spouse must be a taxpayer"
            );
            if (ITaxpayer(newSpouse).isMarried()) {
                require(ITaxpayer(newSpouse).getSpouse() == address(this), "you cannot marry a married taxpayer");
            }
            marriage.spouse = newSpouse;
            marriage.maxAllowance = Taxpayer(address(this)).getTaxAllowance() + ITaxpayer(newSpouse).getTaxAllowance();
            ITaxpayer(newSpouse).marry(address(this));
        }
    }

    function divorce() public {
        // taxAllowance = DEFAULT_ALLOWANCE;
        if (isMarried()) {
            address oldSpouse = marriage.spouse;
            marriage.spouse = address(0); // non serve mettere maxTaxAllowance a zero. Più gas efficient
            ITaxpayer(oldSpouse).divorce();
        }
    }

    /* Transfer part of tax allowance to own spouse */
    function transferAllowance(uint256 change) public {
        require(isMarried(), "you must be married to transfer allowance");
        require(taxAllowance >= change, "cannot change more than the taxAllowance holded");
        taxAllowance = taxAllowance - change;
        ITaxpayer sp = ITaxpayer(address(marriage.spouse));
        sp.setTaxAllowance(sp.getTaxAllowance() + change);
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
    function setTaxAllowance(uint256 ta) public {
        // require(Taxpayer(msg.sender).isContract() || Lottery(msg.sender).isContract());
        // This pre-condition is wrong. Use ERC-165 instead
        require(
            doesContractImplementInterface(address(msg.sender), type(ITaxpayer).interfaceId)
                || doesContractImplementInterface(address(msg.sender), type(ILottery).interfaceId),
            "Not ITaxpayer or Lottery"
        );
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
        rev = 0;
        joinedLottery = address(0);
    }

    function winLottery() external {
        require(msg.sender == joinedLottery);
        taxAllowance += 2000;
        if (isMarried()) {
            marriage.maxAllowance += 2000; // (ALLOWANCE_OAP - DEFAULT_ALLOWANCE);
            ITaxpayer(ITaxpayer(address(this)).getSpouse()).redeemTaxAllowanceOfSpouse(2000);
        }
    }
}
