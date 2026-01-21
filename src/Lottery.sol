// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {ILotteryReceiver} from "./Taxpayer.sol";

import {IERC165} from "forge-std/interfaces/IERC165.sol";

import {ERC165Query} from "./ERC165Query.sol";

import "./BokkyPooBahsDateTimeLibrary.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

using BokkyPooBahsDateTimeLibrary for uint256;

interface ILottery is IERC165 {
    function startLottery() external;
    function commit(bytes32 y) external;
    function reveal(uint256 rev) external;
    function endLottery() external returns (address);
}

contract Lottery is ILottery, ERC165Query {
    enum State {
        NotStarted,
        Started,
        Ending
    }

    event Message(string);

    function _assert(bool condition, string memory message) internal {
        if (!condition) {
            emit Message(message);
            emit AssertionFailed(1);
        }
    }
    event AssertionFailed(uint256);

    mapping(bytes4 => bool) supportedInterfaces;

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return supportedInterfaces[interfaceId];
    }

    // address public owner;
    mapping(uint256 => mapping(address => bytes32)) public commits;
    mapping(uint256 => mapping(address => uint256)) public reveals;
    mapping(uint256 => address[]) public revealed;

    uint256 iteration = 0;
    // uint256 public startTime;
    // uint256 public revealTime;
    // uint256 public endTime;
    // uint256 public period;

    State state;

    // Initialize the registry with the lottery period.
    constructor(uint256 p) {
        // period = p;
        // startTime = 0;
        // endTime = 0;
        // owner = msg.sender;

        supportedInterfaces[type(IERC165).interfaceId] = true;
        supportedInterfaces[type(ILottery).interfaceId] = true;
        state = State.NotStarted;
        iteration = 0;
    }

    //If the lottery has not started, anyone can invoke a lottery.
    function startLottery() public {
        require(State.NotStarted == state);
        // require(msg.sender == owner);
        state = State.Started;
    }

    //A taxpayer send his own commitment.
    function commit(bytes32 y) public {
        // require(block.timestamp >= startTime);
        require(State.Started == state);
        require(
            doesContractImplementInterface(msg.sender, type(ILotteryReceiver).interfaceId),
            "the contract doen't implement ILotteryReceiver interface"
        );
        commits[iteration][msg.sender] = y;
    }

    function endCommit() public {
        require(state == State.Started);
        state = State.Ending;
    }

    //A valid taxpayer who sent his own commitment, sends the revealing value.
    function reveal(uint256 rev) public {
        // require(block.timestamp >= revealTime);
        require(State.Ending == state);
        require(keccak256(abi.encode(rev)) == commits[iteration][msg.sender]);
        revealed[iteration].push(msg.sender);
        reveals[iteration][msg.sender] = uint256(rev);
    }

    //Ends the lottery and compute the winner.
    // returns the address of the winner
    function endLottery() public returns (address) {
        // require(block.timestamp >= endTime);
        // require(revealed.length > 0);
        require(State.Ending == state, "Not good state.");
        require(revealed[iteration].length > 0, "No one was revealed.");
        uint256 total = 0;
        for (uint256 i = 0; i < revealed[iteration].length; i++) {
            total += reveals[iteration][revealed[iteration][i]] % revealed[iteration].length;
        }
        address winner = revealed[iteration][total % revealed[iteration].length];
        state = State.NotStarted;
        iteration += 1;
        ILotteryReceiver(winner).winLottery();
        return winner;
    }
}
