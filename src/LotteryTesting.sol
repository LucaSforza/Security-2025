// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Taxpayer} from "../src/Taxpayer.sol";
import {Lottery} from "../src/Lottery.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

contract EchidnaTesting {
    Taxpayer[] taxpayers;
    mapping(address => uint256) wins;
    Lottery lottery;
    uint256 total_ends;

    constructor() {
        addTaxpayer();
        addTaxpayer();
        addTaxpayer();
        addTaxpayer();
        addTaxpayer();
        addOldTaxpayer();
        addOldTaxpayer();

        lottery = new Lottery(0);
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

    function getAddress(uint256 index) internal view returns (address) {
        return address(taxpayers[index]);
    }

    function addTaxpayer() internal {
        taxpayers.push(new Taxpayer(address(0), address(0), 28, 5, 2003));
    }

    function addOldTaxpayer() internal {
        taxpayers.push(new Taxpayer(address(0), address(0), 28, 5, 1950));
    }

    function getRandomNumber(uint256 seed) internal view returns (uint256) {
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, msg.sender, seed)));
        return randomHash;
    }

    event Message(string);

    function _assert(bool condition, string memory message) internal {
        if (!condition) {
            emit Message(message);
            emit AssertionFailed(1);
        }
    }
    event AssertionFailed(uint256);

    event LotteryEnded(uint256);

    function create_lottery() public {
        lottery.startLottery();
    }

    function joinAll() public {
        // Pre-condizione: lotteria creata
        for (uint256 index = 0; index < taxpayers.length; index++) {
            taxpayers[index].joinLottery(address(lottery), getRandomNumber(index));
        }
    }

    function revealAll() public {
        for (uint256 index = 0; index < taxpayers.length; index++) {
            taxpayers[index].revealLottery();
        }
    }

    function endCommit() public {
        lottery.endCommit();
    }

    function endLottery() public {
        address winner;

        try lottery.endLottery() returns (address res) {
            winner = res;
            wins[winner] += 1;
            total_ends += 1;
        } catch Error(string memory ciao) {
            bytes32 hash = keccak256(bytes(ciao));
            if (hash == keccak256(bytes("Not good state.")) || hash == keccak256(bytes("No one was revealed."))) {
                emit Message(ciao);
            } else {
                emit AssertionFailed(0);
            }
        } catch (bytes memory) {
            emit AssertionFailed(1);
        } catch Panic(uint256 c) {
            emit Message(Strings.toString(c));
            emit AssertionFailed(2);
        }
    }

    function echidna_check_lottery() public view returns (bool) {
        (address minAddress, uint256 minValue) = getMinWins();
        (address maxAddress, uint256 maxValue) = getMaxWins();

        // if (wins[address(0)] > 0) return false; // TODO: qua da false

        // Allow the lottery to run!
        // Only check the distribution statistics after enough data is collected.
        if (total_ends < 2) return true;
        // Check if the spread between winners is acceptable
        // Note: < 1 implies everyone has the EXACT same number of wins, which is statistically unlikely.
        // You might want a higher threshold like < 5 depending on the number of iterations.
        return false;
        // return (maxValue - minValue) < 10;
    }
}
