#!/usr/bin/env bash
#
# PostToolUse hook wrapper
# Reads JSON from stdin, extracts metadata, and calls session-tracker
#

set -euo pipefail

# Debug logging
DEBUG_LOG="/tmp/leeroy-hook-debug.log"
echo "=== PostToolUse Hook Called $(date) ===" >> "$DEBUG_LOG"

# Read JSON from stdin
HOOK_INPUT=$(cat)

# Log what we received
echo "Received stdin: ${HOOK_INPUT:0:200}..." >> "$DEBUG_LOG"

# Extract values from JSON
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // ""')
TOOL_INPUT_PATH=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // ""')

echo "Tool: $TOOL_NAME, Path: $TOOL_INPUT_PATH, Transcript: $TRANSCRIPT_PATH" >> "$DEBUG_LOG"

# Only track file modifications for relevant tools
if [[ "$TOOL_NAME" =~ ^(Write|Edit)$ ]] && [[ -n "$TOOL_INPUT_PATH" ]]; then
    echo "Tracking file modification" >> "$DEBUG_LOG"

    # Extract model from transcript if available (use tail -1 to get most recent model)
    if [[ -f "$TRANSCRIPT_PATH" ]]; then
        echo "Transcript file exists" >> "$DEBUG_LOG"
        MODEL=$(grep '"type":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null | tail -1 | jq -r '.message.model // "unknown"' 2>/dev/null || echo "unknown")
        echo "Extracted model: $MODEL" >> "$DEBUG_LOG"
        export CLAUDE_MODEL="$MODEL"
    else
        echo "Transcript file not found: $TRANSCRIPT_PATH" >> "$DEBUG_LOG"
    fi

    # Get Claude Code version
    VERSION=$(claude --version 2>/dev/null | head -n1 | cut -d' ' -f1 || echo "unknown")
    echo "Extracted version: $VERSION" >> "$DEBUG_LOG"
    export CLAUDE_CODE_VERSION="$VERSION"

    # Call session tracker (this will initialize session with env vars if needed)
    /home/metcalfc/.leeroy/hooks/session-tracker.sh file "$TOOL_INPUT_PATH" modified

    # Always update session with latest model/version from transcript
    if [[ -f "$HOME/.leeroy/current-session.json" ]]; then
        # Update if we have valid data from transcript (not "unknown")
        if [[ "$MODEL" != "unknown" ]] || [[ "$VERSION" != "unknown" ]]; then
            echo "Updating session with model=$MODEL version=$VERSION" >> "$DEBUG_LOG"
            TMP=$(mktemp)
            jq --arg model "$MODEL" --arg version "$VERSION" \
               '.model = $model | .tool_version = $version' \
               "$HOME/.leeroy/current-session.json" > "$TMP" && mv "$TMP" "$HOME/.leeroy/current-session.json"
        fi
    fi
else
    echo "Not tracking (tool=$TOOL_NAME, path=$TOOL_INPUT_PATH)" >> "$DEBUG_LOG"
fi

exit 0
