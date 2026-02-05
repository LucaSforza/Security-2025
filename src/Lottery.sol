// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {ILotteryReceiver} from "./Taxpayer.sol";

import {IERC165} from "forge-std/interfaces/IERC165.sol";

import {ERC165Query} from "./ERC165Query.sol";

import "./BokkyPooBahsDateTimeLibrary.sol";

import "./FactoryTaxpayer.sol";

using BokkyPooBahsDateTimeLibrary for uint256;

interface ILottery is IERC165 {
    function startLottery() external;
    function join(address taxpayer) external;
    function endLottery(bytes32 _sealedSeed) external;
    function selectWinner(uint256 seed) external returns (address);
}

contract Lottery is ILottery, ERC165Query {
    enum State {
        NotStarted,
        Ending,
        Started
    }

    event Message(string);

    function _assert(bool condition, string memory message) internal {
        if (!condition) {
            emit Message(message);
            emit AssertionFailed(1);
        }
    }

    event AssertionFailed(uint256);

    mapping(bytes4 => bool) private supportedInterfaces;

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return supportedInterfaces[interfaceId];
    }

    address immutable owner;
    mapping(uint256 => mapping(address => bool)) private joined;
    mapping(uint256 => address[]) private listJoined;

    uint256 private iteration = 0;
    // uint256 public startTime;
    // uint256 public revealTime;
    // uint256 public endTime;
    // uint256 public period;

    State private state;

    FactoryTaxpayer private f;

    // Initialize the registry with the lottery period.
    constructor(FactoryTaxpayer factory, address _owner) {
        // period = p;
        // startTime = 0;
        // endTime = 0;
        owner = _owner;
        f = factory;
        supportedInterfaces[type(IERC165).interfaceId] = true;
        supportedInterfaces[type(ILottery).interfaceId] = true;
        state = State.NotStarted;
        iteration = 0;
    }

    // Randomness provided by this is predicatable. Use with care!

    //If the lottery has not started, anyone can invoke a lottery.
    function startLottery() public {
        require(State.NotStarted == state);
        require(msg.sender == owner);
        state = State.Started;
    }

    function join(address taxpayer) public {
        require(State.Started == state);

        require(f.isTaxpayer(taxpayer));

        require(joined[iteration][taxpayer] == false, "already joined");
        joined[iteration][taxpayer] = false;
        listJoined[iteration].push(taxpayer);
    }

    uint256 futureBlock;
    bytes32 sealedSeed;

    function endLottery(bytes32 _sealedSeed) public {
        require(owner == msg.sender);
        require(State.Started == state, "Not good state.");
        require(listJoined[iteration].length > 0, "No one was joined.");

        state = State.Ending;
        futureBlock = block.number + 1;
        sealedSeed = _sealedSeed;
    }

    function randomNumber(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed, blockhash(block.number))));
    }

    function selectWinner(uint256 seed) public returns (address) {
        require(owner == msg.sender);
        require(State.Ending == state, "Not good state.");
        require(listJoined[iteration].length > 0, "No one was joined.");
        require(keccak256(abi.encodePacked(owner, seed)) == sealedSeed);
        require(block.number >= futureBlock);
        address winner = listJoined[iteration][randomNumber(seed) % listJoined[iteration].length];
        state = State.NotStarted;
        iteration += 1;
        ILotteryReceiver(winner).winLottery();
        return winner;
    }
}
