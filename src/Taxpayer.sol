// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Lottery} from "./Lottery.sol";

import {IERC165} from "forge-std/interfaces/IERC165.sol";

import {ERC165Query} from "./ERC165Query.sol";

interface ILotteryReceiver {
    function joinLottery(address lot, uint256 r) external;
    function revealLottery(address lot, uint256 r) external;
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
}

contract Taxpayer is ITaxpayer, ERC165Query {
    // uint256 age; This is wrong! a taxpayer should increment his age every birthday manually
    // This can add a lot of costs beacuse updating this attribute need GAS to be updated.
    uint256 public birthday; // changed created attribute public

    struct Marriage {
        address spouse;
        uint256 maxAllowance;
    } // TODO: document

    /* Reference to spouse if person is married, address(0) otherwise */
    Marriage public marriage;

    // bool public isMarried; changed in to a function, more GAS efficient
    function isMarried() public view returns (bool) {
        return marriage.spouse != address(0);
    }

    function getMaxTaxAllowance() external view returns (uint256 maxAllowance) {
      if (isMarried()) {
        maxAllowance = marriage.maxAllowance;
      } else {
        maxAllowance = 0;
      }
    }

    // bool iscontract; changed Can we do better using ERC-165

    address public parent1; // changed in to public
    address public parent2;

    /* Constant default income tax allowance */
    uint256 public constant DEFAULT_ALLOWANCE = 5000;

    /* Constant income tax allowance for Older Taxpayers over 65 */
    uint256 public constant ALLOWANCE_OAP = 7000;

    /* Income tax allowance */
    uint256 private taxAllowance;

    uint256 public income; // changed to public

    uint256 private rev; // changed must be private

    //Parents are taxpayers
    constructor(address p1, address p2, uint256 _birthday) {
        // changed new constructor argument and pre-condition to check if the birthday is consistent
        // changed pre-condition about the interface of parents
        require(_birthday < block.timestamp, "not possible to create a Taxpayer of someone not born yet");
        if (p1 != address(0)) {
            require(doesContractImplementInterface(p1, type(ITaxpayer).interfaceId), "parent1 is not a Taxpayer");
        }
        if (p2 != address(0)) {
            require(doesContractImplementInterface(p2, type(ITaxpayer).interfaceId), "parent2 is not a Taxpayer");
        }
        birthday = _birthday;
        parent1 = p1;
        parent2 = p2;
        marriage.spouse = address(0);
        income = 0;
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
        if (!isMarried()) {
            require(newSpouse != address(this));
            require(
                doesContractImplementInterface(newSpouse, type(ITaxpayer).interfaceId), "the spouse must be a taxpayer"
            );
            require(!ITaxpayer(newSpouse).isMarried(), "the spouse must not be married");
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
        taxAllowance = taxAllowance - change;
        ITaxpayer sp = ITaxpayer(address(marriage.spouse));
        sp.setTaxAllowance(sp.getTaxAllowance() + change);
    }

    function age() public view returns (uint256 _age) {
        _age = block.timestamp - birthday;
    }

    function setTaxAllowance(uint256 ta) public {
        // require(Taxpayer(msg.sender).isContract() || Lottery(msg.sender).isContract());
        // This pre-condition is wrong. Use ERC-165 instead
        require(
            doesContractImplementInterface(address(msg.sender), type(ITaxpayer).interfaceId)
                || Lottery(msg.sender).isContract(),
            "Not ITaxpayer or Lottery"
        );
        // TODO: add ERC-165 to Lottery
        taxAllowance = ta;
    }

    /* function isContract() public view returns (bool) {
        return iscontract;
    } it is useless if we are using ERC-165 */

    function getSpouse() external view returns (address) {
        return marriage.spouse;
    }

    function getTaxAllowance() external view returns (uint256 allowance) {
        return taxAllowance;
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
