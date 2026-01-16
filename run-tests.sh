#!/usr/bin/env bash
set -euo pipefail

# Test runner for Leeroy Toolkit

cd "$(dirname "$0")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🧪 Running Leeroy Toolkit Tests"
echo ""

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo -e "${RED}✗ Error: bats is not installed${NC}"
    echo ""
    echo "Install bats using your package manager:"
    echo "  Arch: sudo pacman -S bats"
    echo "  Ubuntu/Debian: sudo apt-get install bats"
    echo "  macOS: brew install bats-core"
    exit 1
fi

# Parse arguments
VERBOSE=false
TEST_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -f|--file)
            TEST_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -v, --verbose    Show detailed test output"
            echo "  -f, --file FILE  Run only specified test file"
            echo "  -h, --help       Show this help message"
            echo ""
            echo "Test files:"
            echo "  tests/session-tracker.bats  - Session tracking unit tests"
            echo "  tests/signing.bats          - Signing and verification tests"
            echo "  tests/integration.bats      - Full workflow integration tests"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Determine which tests to run
if [[ -n "$TEST_FILE" ]]; then
    if [[ ! -f "$TEST_FILE" ]]; then
        echo -e "${RED}✗ Test file not found: $TEST_FILE${NC}"
        exit 1
    fi
    TEST_FILES=("$TEST_FILE")
else
    TEST_FILES=(
        "tests/session-tracker.bats"
        "tests/signing.bats"
        "tests/integration.bats"
    )
fi

# Run shellcheck on all shell scripts
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Running shellcheck...${NC}"
echo ""

if command -v shellcheck &> /dev/null; then
    SHELLCHECK_FAILED=0

    # Find all shell scripts
    SHELL_SCRIPTS=(
        install.sh
        run-tests.sh
        test-prompt-capture.sh
        hooks/session-tracker.sh
        hooks/log-prompt.sh
        hooks/capture-prompt.sh
        hooks/post-commit-attestation.sh
        hooks/sign-attestation.sh
        hooks/git-prepare-commit-msg
        hooks/git-post-commit
        hooks/git-pre-push
        hooks/git-post-checkout
    )

    for script in "${SHELL_SCRIPTS[@]}"; do
        if [[ -f "$script" ]]; then
            echo -n "  Checking $script... "
            if shellcheck "$script" 2>&1 | grep -v "^$" > /dev/null; then
                echo -e "${RED}✗${NC}"
                shellcheck "$script"
                SHELLCHECK_FAILED=1
            else
                echo -e "${GREEN}✓${NC}"
            fi
        fi
    done

    echo ""
    if [[ $SHELLCHECK_FAILED -eq 1 ]]; then
        echo -e "${RED}✗ Shellcheck found issues${NC}"
        echo ""
        exit 1
    fi

    echo -e "${GREEN}✓ All scripts passed shellcheck${NC}"
else
    echo -e "${YELLOW}⚠️  shellcheck not found, skipping${NC}"
    echo "   Install with: sudo pacman -S shellcheck"
fi

echo ""

# Run tests
FAILED=0
PASSED=0

for test_file in "${TEST_FILES[@]}"; do
    echo -e "${YELLOW}Running: $test_file${NC}"

    if [[ "$VERBOSE" == "true" ]]; then
        if bats "$test_file"; then
            PASSED=$((PASSED + 1))
        else
            FAILED=$((FAILED + 1))
        fi
    else
        if bats --formatter tap "$test_file" | grep -E "^(ok|not ok|1\.\.|#)" | tail -1; then
            PASSED=$((PASSED + 1))
            echo -e "${GREEN}✓ Passed${NC}"
        else
            FAILED=$((FAILED + 1))
            echo -e "${RED}✗ Failed${NC}"
        fi
    fi
    echo ""
done

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary:"
echo -e "  ${GREEN}Passed: $PASSED${NC}"
echo -e "  ${RED}Failed: $FAILED${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $FAILED -gt 0 ]]; then
    echo ""
    echo -e "${RED}Some tests failed. Run with -v for details.${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
fi
