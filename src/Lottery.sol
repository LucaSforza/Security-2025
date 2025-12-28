// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {ITaxpayer, ILotteryReceiver} from "./Taxpayer.sol";

import {IERC165} from "forge-std/interfaces/IERC165.sol";

import {ERC165Query} from "./ERC165Query.sol";

import "./BokkyPooBahsDateTimeLibrary.sol";

using BokkyPooBahsDateTimeLibrary for uint256;

interface ILottery is IERC165 {
    function startLottery() external;
    function commit(bytes32 y) external;
    function reveal(uint256 rev) external;
    function endLottery() external;
}

contract Lottery is ILottery, ERC165Query {
    mapping(bytes4 => bool) supportedInterfaces;

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return supportedInterfaces[interfaceId];
    }

    address owner;
    mapping(address => bytes32) commits;
    mapping(address => uint256) reveals;
    address[] revealed;

    uint256 startTime;
    uint256 revealTime;
    uint256 endTime;
    uint256 period;

    // Initialize the registry with the lottery period.
    constructor(uint256 p) {
        period = p;
        startTime = 0;
        endTime = 0;
        owner = msg.sender;

        supportedInterfaces[type(IERC165).interfaceId] = true;
        supportedInterfaces[type(ILottery).interfaceId] = true;
    }

    //If the lottery has not started, anyone can invoke a lottery.
    function startLottery() public {
        require(startTime == 0);
        //startTime current time. Users send their committed value
        startTime = block.timestamp;
        //revealTime  time for revealing. User reveal their value
        revealTime = startTime + period;
        //endTime a winner can be computed
        endTime = revealTime + period;
    }

    //A taxpayer send his own commitment.
    function commit(bytes32 y) public {
        require(block.timestamp >= startTime);
        require(
            doesContractImplementInterface(msg.sender, type(ITaxpayer).interfaceId),
            "the contract doen't implement ITaxpayer interface"
        );
        commits[msg.sender] = y;
    }

    //A valid taxpayer who sent his own commitment, sends the revealing value.
    function reveal(uint256 rev) public {
        require(block.timestamp >= revealTime);
        require(keccak256(abi.encode(rev)) == commits[msg.sender]);
        revealed.push(msg.sender);
        reveals[msg.sender] = uint256(rev);
    }

    //Ends the lottery and compute the winner.
    function endLottery() public {
        require(block.timestamp >= endTime);
        uint256 total = 0;
        for (uint256 i = 0; i < revealed.length; i++) {
            total += reveals[revealed[i]];
        }
        ITaxpayer(revealed[total % revealed.length]).setTaxAllowance(7000);
        startTime = 0;
        revealTime = 0;
        endTime = 0;
    }
}
