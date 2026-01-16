#!/usr/bin/env bash
# hooks/capture-prompt.sh
# Automatically captures user prompts when submitted to Claude Code
# Called by Claude Code's UserPromptSubmit hook

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_TRACKER="${SCRIPT_DIR}/session-tracker.sh"

# Read prompt JSON from STDIN
prompt_json=$(cat)

# Debug: log raw JSON for troubleshooting (comment out in production)
# echo "$prompt_json" >> ~/.ai-attestation/prompt-debug.log

# Extract user message text
# Try multiple possible JSON paths since the exact format isn't documented
user_text=$(echo "$prompt_json" | jq -r '.text // .message // .content // .prompt // empty' 2>/dev/null || echo "")

# If jq path extraction fails, try to extract any string value from the JSON
if [[ -z "$user_text" ]]; then
    user_text=$(echo "$prompt_json" | jq -r 'if type == "string" then . else empty end' 2>/dev/null || echo "")
fi

# Log to session if we extracted text
if [[ -n "$user_text" && "$user_text" != "null" ]]; then
    "$SESSION_TRACKER" prompt "$user_text"
fi
