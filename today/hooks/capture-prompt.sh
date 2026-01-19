#!/usr/bin/env bash
#
# Leeroy Inline - Automatic Prompt Capture
# Called by Claude Code's UserPromptSubmit hook
#
# Reads JSON from STDIN and extracts the user's prompt text

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_TRACKER="${SCRIPT_DIR}/session-tracker.sh"

# Read JSON from STDIN
input=$(cat)

# Try to extract the prompt text from various possible JSON structures
prompt_text=""

if [[ -n "${input}" ]]; then
    # Try different possible field names
    for field in ".prompt.content" ".prompt.message" ".prompt.text" ".prompt" ".message" ".content" ".text"; do
        candidate=$(echo "${input}" | jq -r "${field} // empty" 2>/dev/null || true)
        if [[ -n "${candidate}" && "${candidate}" != "null" ]]; then
            prompt_text="${candidate}"
            break
        fi
    done
fi

# If we found a prompt, log it
if [[ -n "${prompt_text}" ]]; then
    "${SESSION_TRACKER}" prompt "${prompt_text}"
fi
