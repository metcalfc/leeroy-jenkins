#!/usr/bin/env bash
#
# Leeroy Inline - Post Tool Use Wrapper
# Called by Claude Code's PostToolUse hook
#
# Extracts model/version info and tracks file modifications

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_TRACKER="${SCRIPT_DIR}/session-tracker.sh"

# Read JSON from STDIN
input=$(cat)

# Extract tool name
tool_name=$(echo "${input}" | jq -r '.tool_name // empty' 2>/dev/null || true)

# Only track Write and Edit tools
if [[ "${tool_name}" != "Write" && "${tool_name}" != "Edit" ]]; then
    exit 0
fi

# Extract file path
file_path=$(echo "${input}" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)

if [[ -z "${file_path}" ]]; then
    exit 0
fi

# Try to extract model from transcript
transcript_path=$(echo "${input}" | jq -r '.transcript_path // empty' 2>/dev/null || true)

if [[ -n "${transcript_path}" && -f "${transcript_path}" ]]; then
    # Get model from most recent assistant message
    model=$(tac "${transcript_path}" | grep -m1 '"type":"assistant"' | jq -r '.message.model // empty' 2>/dev/null || true)
    if [[ -n "${model}" ]]; then
        export CLAUDE_MODEL="${model}"
    fi
fi

# Get Claude Code version
if command -v claude &>/dev/null; then
    version=$(claude --version 2>/dev/null | head -1 || true)
    export CLAUDE_CODE_VERSION="${version}"
fi

# Determine modification type
if [[ -f "${file_path}" ]]; then
    mod_type="modified"
else
    mod_type="created"
fi

# Log the file modification
"${SESSION_TRACKER}" file "${file_path}" "${mod_type}"

# Update session with model/version (env vars only used during init)
SESSION_FILE="${HOME}/.leeroy/current-session.json"
if [[ -f "${SESSION_FILE}" ]]; then
    model="${CLAUDE_MODEL:-}"
    version="${CLAUDE_CODE_VERSION:-}"
    if [[ -n "${model}" || -n "${version}" ]]; then
        tmp=$(mktemp)
        jq --arg model "${model:-unknown}" --arg version "${version:-unknown}" \
           '.model = $model | .tool_version = $version' \
           "${SESSION_FILE}" > "$tmp" && mv "$tmp" "${SESSION_FILE}"
    fi
fi
