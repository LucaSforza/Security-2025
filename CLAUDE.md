# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Compile contracts
forge build

# Run all Forge tests
forge test

# Run a specific test
forge test --match-contract LotteryTest -vvv

# Run Echidna fuzzing (uses config in src/echidna.yaml)
# Must have echidna installed: echidna src/Testing.sol --contract EchidnaTesting --config src/echidna.yaml

# Format Solidity
forge fmt
```

## Project Overview

University security course project (Sapienza). Foundry-based Solidity smart contracts modeling a tax authority system with marriage, allowance transfers, and lottery mechanics. Developed using Agile methodology across 4 iterations.

### Core Contracts (`src/`)

- **FactoryTaxpayer.sol** — Central registry. Owns the Lottery instance, creates & tracks all Taxpayer contracts. Single source of truth for "is this a valid taxpayer?" queries.
- **Taxpayer.sol** — Main domain contract. Tracks birth date (not age — age is computed via timestamp), marriage state, tax allowance. Implements `ITaxpayer` + `ILotteryReceiver`. Uses **ReentrancyGuard** on marriage functions. Age calculated via `BokkyPooBahsDateTimeLibrary`.
- **Lottery.sol** — State machine (NotStarted → Started → Ending → NotStarted). Uses blockhash-based randomness with sealed seed commitment. Owner-only start/end/selectWinner. Winner drawn after 1-block delay.
- **ERC165Query.sol** — Assembly-level ERC-165 interface detection. Used instead of `isContract()` to verify interface compliance.

### Forge Tests (`test/`) — Primary test suite

- **test/Taxpayer.t.sol** — Handler-based invariant tests. `TaxpayerHandler` wraps state-changing calls (marry, divorce, redeem, transferAllowance) with 7 taxpayers (5 young + 2 old). 3 invariants: spouse symmetry, redeem age ≥65, married allowance sum == maxAllowance.
- **test/Lottery.t.sol** — Handler-based invariant tests. `LotteryHandler` wraps full lottery rounds (start → join → end → selectWinner). 1 invariant: win distribution spread <25 after 5+ rounds. **Known limitation**: `blockhash(block.number)` = 0 in Foundry, making randomness deterministic from seed alone — invariant may fail probabilistically.

### Echidna Fuzz Testing (legacy, kept for reference)

- **src/Testing.sol** — EchidnaHarness for Taxpayer invariants
- **src/LotteryTesting.sol** — EchidnaHarness for Lottery invariants
- **src/echidna.yaml** — Config: property-based, deployer=0x10000, allContracts=false

### Justfile

`justfile` has recipes for both test suites:
- `just test-all` / `just test-contracts` — Forge commands
- `just fuzz-all` / `just fuzz-taxpayer` / `just fuzz-lottery` — Echidna commands
- `just test-deep` — Forge with 10k fuzz runs
- `just fuzz-smoke` — Echidna with low iterations

### Key Invariants

1. **Spouse reciprocity**: If A is married to B, then B's spouse must be A
2. **Tax allowance sum**: Married couples' allowances must equal the `marriage.maxAllowance`
3. **Redeem age check**: Only taxpayers ≥65 can redeem OAP allowance
4. **Lottery fairness**: After many rounds, win count variance across players stays bounded

### Dependencies

- `forge-std` — Foundry standard library (Test, console)
- `openzeppelin-contracts` — ReentrancyGuard, Strings
- `BokkyPooBahsDateTimeLibrary` — Unix timestamp → date conversion

### Report

`design/report/main2.tex` — IEEEtran LaTeX paper documenting the full project.
