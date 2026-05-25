# Test recipes for Taxpayer + Lottery contracts
# Usage: just <recipe> [workers=8] [limit=50000]

workers := "8"
limit := "50000"
config := "src/echidna.yaml"

# ── Echidna fuzz tests ──────────────────────────────────────────

# Run all Echidna tests in parallel
fuzz-all: fuzz-taxpayer fuzz-lottery

# Run Taxpayer invariants (spouse, redeem, tax allowance)
fuzz-taxpayer:
    echidna src/Testing.sol \
        --contract EchidnaTesting \
        --config {{config}} \
        --workers {{workers}} \
        --test-limit {{limit}}

# Run Lottery invariants (win distribution fairness)
fuzz-lottery:
    echidna src/LotteryTesting.sol \
        --contract EchidnaTesting \
        --config {{config}} \
        --workers {{workers}} \
        --test-limit {{limit}}

# Quick Echidna smoke test (low iterations)
fuzz-smoke:
    just --justfile {{justfile()}} workers=4 limit=5000 fuzz-all

# ── Forge unit + invariant tests ────────────────────────────────

# Run all Forge tests
test-all:
    forge test -j 12

# Run Taxpayer invariants & unit tests
test-taxpayer:
    forge test --match-contract TaxpayerTest -j 12

# Run Lottery invariant tests
test-lottery:
    forge test --match-contract LotteryTest -j 12

# Run both contract-specific test files
test-contracts: test-taxpayer test-lottery

# Run contract tests with extra fuzz runs
test-deep:
    FOUNDRY_FUZZ_RUNS=10000 forge test 

# ── Halmos symbolic tests ──────────────────────────────────────────

# Run all Halmos symbolic tests
halmos-all:
    halmos --verbose

# Run Taxpayer symbolic tests
halmos-taxpayer:
    halmos --match-contract TaxpayerSym --verbose

# Run Lottery symbolic tests
halmos-lottery:
    halmos --match-contract LotterySym --verbose

# Display available recipes
default:
    @just --list
