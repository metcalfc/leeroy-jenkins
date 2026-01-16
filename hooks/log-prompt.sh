#!/usr/bin/env bash
#
# Quick prompt logger
# Usage: log-prompt "your prompt here"
#    or: log-prompt (will prompt interactively)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_TRACKER="${SCRIPT_DIR}/session-tracker.sh"

if [[ $# -gt 0 ]]; then
    prompt="$*"
else
    echo -n "Enter prompt: "
    read -r prompt
fi

if [[ -n "${prompt}" ]]; then
    "${SESSION_TRACKER}" prompt "${prompt}"
    echo "✓ Prompt logged"
else
    echo "No prompt provided" >&2
    exit 1
fi
