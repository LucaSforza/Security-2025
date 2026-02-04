// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Taxpayer} from "../src/Taxpayer.sol";
import {Lottery} from "../src/Lottery.sol";

import "./FactoryTaxpayer.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

contract EchidnaTesting {
    Taxpayer[] taxpayers;
    mapping(address => uint256) wins;
    Lottery lottery;
    FactoryTaxpayer private f;
    uint256 total_ends;

    event Message(bytes);

    constructor() {
        f = new FactoryTaxpayer(address(this));
        addTaxpayer();
        addTaxpayer();
        addTaxpayer();
        addTaxpayer();
        addTaxpayer();
        addOldTaxpayer();
        addOldTaxpayer();

        lottery = Lottery(f.getLottery());
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
        minAddress = address(0);
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
        address t = f.createTaxpayer(address(0), address(0), 28, 5, 2003);
        taxpayers.push(Taxpayer(t));
    }

    function addOldTaxpayer() internal {
        address t = f.createTaxpayer(address(0), address(0), 28, 5, 1950);
        taxpayers.push(Taxpayer(t));
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

    function create_lottery() internal {
        lottery.startLottery();
    }

    function joinAll() internal {
        // Pre-condizione: lotteria creata
        for (uint256 index = 0; index < taxpayers.length; index++) {
            taxpayers[index].joinLottery();
        }
    }

    function endLottery() internal {
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

    function complete_iteration() public {
        create_lottery();

        joinAll();

        endLottery();
        wait(1 weeks);
        selectWinner();
    }

    function echidna_check_lottery() public view returns (bool) {
        (address minAddress, uint256 minValue) = getMinWins();
        (address maxAddress, uint256 maxValue) = getMaxWins();

        if (wins[address(0)] > 0) return false;
        if (total_ends < 5) return true;
        return maxValue - minValue < 25;
    }
}
