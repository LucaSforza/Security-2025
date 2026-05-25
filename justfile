# Echidna fuzzing recipes for Taxpayer + Lottery contracts
# Usage: just <recipe> [workers=8] [limit=50000]

workers := "8"
limit := "50000"
config := "src/echidna.yaml"

# Run all fuzz tests in parallel
fuzz-all: fuzz-taxpayer fuzz-lottery

# Run only Taxpayer invariants (spouse, redeem, tax allowance)
fuzz-taxpayer:
    echidna src/Testing.sol \
        --contract EchidnaTesting \
        --config {{config}} \
        --workers {{workers}} \
        --test-limit {{limit}}

# Run only Lottery invariants (win distribution fairness)
fuzz-lottery:
    echidna src/LotteryTesting.sol \
        --contract EchidnaTesting \
        --config {{config}} \
        --workers {{workers}} \
        --test-limit {{limit}}

# Quick smoke test (low iterations)
fuzz-smoke:
    just --justfile {{justfile()}} workers=4 limit=5000 fuzz-all

# Display available recipes
default:
    @just --list
