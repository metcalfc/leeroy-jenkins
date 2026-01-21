#!/usr/bin/env bash
#
# Leeroy - Post Tool Use Hook
# Called by Claude Code's PostToolUse hook
#
# Extracts model/version info and tracks file modifications

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly SESSION_TRACKER="${SCRIPT_DIR}/session-tracker.sh"

# Read JSON from stdin
input=$(cat)

# Extract tool name - only track Write and Edit
tool_name=$(echo "${input}" | jq -r '.tool_name // empty' 2>/dev/null || true)
if [[ "${tool_name}" != "Write" && "${tool_name}" != "Edit" ]]; then
    exit 0
fi

# Extract file path
file_path=$(echo "${input}" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
[[ -z "${file_path}" ]] && exit 0

# Determine modification type (before converting to relative path)
if [[ -f "${file_path}" ]]; then
    mod_type="modified"
else
    mod_type="created"
fi

# Convert to relative path from git repo root (avoid leaking filesystem paths)
if git rev-parse --git-dir &>/dev/null; then
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
    if [[ -n "${repo_root}" && "${file_path}" == "${repo_root}"/* ]]; then
        file_path="${file_path#"${repo_root}"/}"
    fi
fi

# Extract model from transcript (portable: works on macOS and Linux)
transcript_path=$(echo "${input}" | jq -r '.transcript_path // empty' 2>/dev/null || true)
if [[ -n "${transcript_path}" && -f "${transcript_path}" ]]; then
    # Use tail -r on macOS, tac on Linux (or grep with tail as fallback)
    if command -v tac &>/dev/null; then
        model=$(tac "${transcript_path}" | grep -m1 '"type":"assistant"' | jq -r '.message.model // empty' 2>/dev/null || true)
    else
        # Portable fallback: grep all, take last line
        model=$(grep '"type":"assistant"' "${transcript_path}" 2>/dev/null | tail -1 | jq -r '.message.model // empty' 2>/dev/null || true)
    fi
    [[ -n "${model}" ]] && export CLAUDE_MODEL="${model}"
fi

# Get Claude Code version
if command -v claude &>/dev/null; then
    version=$(claude --version 2>/dev/null | head -1 || true)
    export CLAUDE_CODE_VERSION="${version}"
fi

# Log the file modification
"${SESSION_TRACKER}" file "${file_path}" "${mod_type}"

# Update session with model/version if available
SESSION_FILE=$("${SESSION_TRACKER}" path)
if [[ -f "${SESSION_FILE}" ]]; then
    model="${CLAUDE_MODEL:-}"
    version="${CLAUDE_CODE_VERSION:-}"
    if [[ -n "${model}" || -n "${version}" ]]; then
        tmp=$(mktemp)
        jq --arg model "${model:-unknown}" --arg version "${version:-unknown}" \
           '.model = $model | .tool_version = $version' \
           "${SESSION_FILE}" > "${tmp}" && mv "${tmp}" "${SESSION_FILE}"
    fi
fi
