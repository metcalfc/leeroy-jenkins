#!/usr/bin/env bash
#
# Test runner for Leeroy Toolkit (Today Version)

set -euo pipefail

cd "$(dirname "$0")"

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo "Error: bats is not installed"
    echo ""
    echo "Install bats using your package manager:"
    echo "  macOS: brew install bats-core"
    echo "  Ubuntu/Debian: sudo apt-get install bats"
    exit 1
fi

# Run all test files or specific file if provided
if [[ $# -gt 0 ]]; then
    bats "$@"
else
    bats *.bats
fi
