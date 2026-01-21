#!/usr/bin/env bash
#
# Leeroy Session Tracker
# Tracks AI-assisted editing activity for commit attestation

set -euo pipefail

readonly LEEROY_DIR="${HOME}/.leeroy"
readonly SESSIONS_DIR="${LEEROY_DIR}/sessions"
readonly PROMPT_LOG="${LEEROY_DIR}/prompts.log"

mkdir -p "${SESSIONS_DIR}"

# Get session file path for the current git worktree
# Each worktree/repo gets its own session file based on path hash
get_session_file() {
    local git_root=""

    # Try to get git worktree root
    if git rev-parse --show-toplevel &>/dev/null; then
        git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    fi

    if [[ -n "${git_root}" ]]; then
        # Hash the git root path to create a unique session key
        local hash
        hash=$(echo -n "${git_root}" | openssl dgst -sha256 | awk '{print $2}' | cut -c1-16)
        echo "${SESSIONS_DIR}/${hash}.json"
    else
        # Fallback for non-git directories (rare case)
        echo "${SESSIONS_DIR}/default.json"
    fi
}

# Get the session file path - can be overridden by LEEROY_SESSION_FILE env var
SESSION_FILE="${LEEROY_SESSION_FILE:-$(get_session_file)}"

# Check for jq dependency
if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not installed" >&2
    exit 1
fi

get_timestamp() {
    date -u +%Y-%m-%dT%H:%M:%SZ
}

init_session() {
    [[ -f "${SESSION_FILE}" ]] && return 0

    local session_id
    session_id=$(openssl rand -hex 8)

    cat > "${SESSION_FILE}" << EOF
{
    "session_id": "${session_id}",
    "started_at": "$(get_timestamp)",
    "tool": "claude-code",
    "tool_version": "${CLAUDE_CODE_VERSION:-unknown}",
    "model": "${CLAUDE_MODEL:-unknown}",
    "files_modified": [],
    "prompts": []
}
EOF
    echo "Session initialized: ${session_id}" >&2
}

log_file_modification() {
    local filepath="${1:-}"
    local mod_type="${2:-modified}"

    [[ -z "${filepath}" ]] && { echo "Error: filepath required" >&2; return 1; }

    init_session

    local tmp
    tmp=$(mktemp)
    jq --arg path "${filepath}" \
       --arg type "${mod_type}" \
       --arg ts "$(get_timestamp)" \
       '.files_modified += [{"path": $path, "type": $type, "timestamp": $ts}]' \
       "${SESSION_FILE}" > "${tmp}" && mv "${tmp}" "${SESSION_FILE}"

    echo "Logged: ${mod_type} ${filepath}" >&2
}

log_prompt() {
    local prompt="${1:-}"

    [[ -z "${prompt}" ]] && { echo "Error: prompt required" >&2; return 1; }

    init_session

    local timestamp
    timestamp=$(get_timestamp)

    local tmp
    tmp=$(mktemp)
    jq --arg prompt "${prompt}" \
       --arg ts "${timestamp}" \
       '.prompts += [{"text": $prompt, "timestamp": $ts}]' \
       "${SESSION_FILE}" > "${tmp}" && mv "${tmp}" "${SESSION_FILE}"

    echo "[${timestamp}] ${prompt}" >> "${PROMPT_LOG}"
    echo "Logged prompt" >&2
}

get_session() {
    if [[ -f "${SESSION_FILE}" ]]; then
        cat "${SESSION_FILE}"
    else
        echo "{}"
    fi
}

clear_session() {
    rm -f "${SESSION_FILE}"
    echo "Session cleared" >&2
}

clear_files() {
    [[ ! -f "${SESSION_FILE}" ]] && return 0

    local tmp
    tmp=$(mktemp)
    jq '.files_modified = []' "${SESSION_FILE}" > "${tmp}" && mv "${tmp}" "${SESSION_FILE}"
    echo "Files cleared (prompts preserved)" >&2
}

show_session_path() {
    echo "${SESSION_FILE}"
}

usage() {
    echo "Usage: $0 {init|file|prompt|get|clear|clear-files|path}" >&2
    exit 1
}

case "${1:-}" in
    init)        init_session ;;
    file)        log_file_modification "${2:-}" "${3:-modified}" ;;
    prompt)      log_prompt "${2:-}" ;;
    get)         get_session ;;
    clear)       clear_session ;;
    clear-files) clear_files ;;
    path)        show_session_path ;;
    *)           usage ;;
esac
