#!/usr/bin/env bash
#
# PostToolUse hook wrapper
# Reads JSON from stdin, extracts metadata, and calls session-tracker
#

set -euo pipefail

# Read JSON from stdin
HOOK_INPUT=$(cat)

# Extract values from JSON
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // ""')
TOOL_INPUT_PATH=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // ""')

# Only track file modifications for relevant tools
if [[ "$TOOL_NAME" =~ ^(Write|Edit)$ ]] && [[ -n "$TOOL_INPUT_PATH" ]]; then
    # Extract model from transcript if available
    if [[ -f "$TRANSCRIPT_PATH" ]]; then
        MODEL=$(grep '"type":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null | head -1 | jq -r '.message.model // "unknown"' 2>/dev/null || echo "unknown")
        export CLAUDE_MODEL="$MODEL"
    fi

    # Get Claude Code version
    VERSION=$(claude --version 2>/dev/null | head -n1 | cut -d' ' -f1 || echo "unknown")
    export CLAUDE_CODE_VERSION="$VERSION"

    # Call session tracker
    /home/metcalfc/.leeroy/hooks/session-tracker.sh file "$TOOL_INPUT_PATH" modified
fi

exit 0
