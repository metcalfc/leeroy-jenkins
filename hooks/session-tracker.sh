#!/usr/bin/env bash
#
# AI Attestation Session Tracker
# Logs AI-assisted editing activity for later attestation
#
# This script is called by Claude Code hooks to track:
# - File modifications
# - Timestamps
# - Session continuity
#
# Prompts must be logged separately (see: log-prompt.sh)

set -euo pipefail

ATTESTATION_DIR="${HOME}/.ai-attestation"
SESSION_FILE="${ATTESTATION_DIR}/current-session.json"
PROMPT_LOG="${ATTESTATION_DIR}/prompts.log"

# Ensure directory exists
mkdir -p "${ATTESTATION_DIR}"

# Initialize session if needed
init_session() {
    if [[ ! -f "${SESSION_FILE}" ]]; then
        local session_id
        session_id=$(openssl rand -hex 8)
        cat > "${SESSION_FILE}" << EOF
{
    "session_id": "${session_id}",
    "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "tool": "claude-code",
    "tool_version": "${CLAUDE_CODE_VERSION:-unknown}",
    "model": "${CLAUDE_MODEL:-unknown}",
    "files_modified": [],
    "prompts": []
}
EOF
        echo "Session initialized: ${session_id}" >&2
    fi
}

# Log a file modification
log_file_modification() {
    local filepath="$1"
    local modification_type="${2:-modified}"  # modified, created, deleted
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    init_session
    
    # Use jq to append to the files_modified array
    local tmp
    tmp=$(mktemp)
    jq --arg path "$filepath" \
       --arg type "$modification_type" \
       --arg ts "$timestamp" \
       '.files_modified += [{"path": $path, "type": $type, "timestamp": $ts}]' \
       "${SESSION_FILE}" > "$tmp" && mv "$tmp" "${SESSION_FILE}"
    
    echo "Logged: ${modification_type} ${filepath}" >&2
}

# Log a prompt (called manually or via wrapper)
log_prompt() {
    local prompt="$1"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    init_session
    
    # Append to prompts array
    local tmp
    tmp=$(mktemp)
    jq --arg prompt "$prompt" \
       --arg ts "$timestamp" \
       '.prompts += [{"text": $prompt, "timestamp": $ts}]' \
       "${SESSION_FILE}" > "$tmp" && mv "$tmp" "${SESSION_FILE}"
    
    # Also append to flat log for easy reading
    echo "[${timestamp}] ${prompt}" >> "${PROMPT_LOG}"
    
    echo "Logged prompt" >&2
}

# Get current session data
get_session() {
    if [[ -f "${SESSION_FILE}" ]]; then
        cat "${SESSION_FILE}"
    else
        echo "{}"
    fi
}

# Clear session (called after commit)
clear_session() {
    rm -f "${SESSION_FILE}"
    echo "Session cleared" >&2
}

# Main dispatch
case "${1:-}" in
    init)
        init_session
        ;;
    file)
        log_file_modification "${2:-}" "${3:-modified}"
        ;;
    prompt)
        log_prompt "${2:-}"
        ;;
    get)
        get_session
        ;;
    clear)
        clear_session
        ;;
    *)
        echo "Usage: $0 {init|file|prompt|get|clear}" >&2
        echo "  init           - Initialize a new session" >&2
        echo "  file <path>    - Log a file modification" >&2
        echo "  prompt <text>  - Log a prompt" >&2
        echo "  get            - Output current session JSON" >&2
        echo "  clear          - Clear the current session" >&2
        exit 1
        ;;
esac
