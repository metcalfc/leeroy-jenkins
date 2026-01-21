#!/usr/bin/env bash
#
# Leeroy - Prompt Capture Hook
# Called by Claude Code's UserPromptSubmit hook
#
# Reads JSON from stdin and extracts the user's prompt text

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly SESSION_TRACKER="${SCRIPT_DIR}/session-tracker.sh"

# Read JSON from stdin
input=$(cat)
[[ -z "${input}" ]] && exit 0

# Try to extract prompt text from various possible JSON structures
# The exact format isn't documented, so we try multiple paths
prompt_text=""
for field in ".prompt.content" ".prompt.message" ".prompt.text" ".prompt" \
             ".message" ".content" ".text"; do
    candidate=$(echo "${input}" | jq -r "${field} // empty" 2>/dev/null || true)
    if [[ -n "${candidate}" && "${candidate}" != "null" ]]; then
        prompt_text="${candidate}"
        break
    fi
done

# Log the prompt if we found one
[[ -n "${prompt_text}" ]] && "${SESSION_TRACKER}" prompt "${prompt_text}"

exit 0
