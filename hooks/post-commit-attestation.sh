#!/usr/bin/env bash
#
# Leeroy Post-Commit Hook
# Attaches AI session metadata to the commit as a git note
#
# This runs after the commit is created (post-commit) to attach the note.
# Git notes can't be attached in pre-commit because the commit doesn't exist yet.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_TRACKER="${SCRIPT_DIR}/session-tracker.sh"
SIGN_ATTESTATION="${SCRIPT_DIR}/sign-attestation.sh"
ATTESTATION_REF="refs/notes/leeroy"

# Get session data
session_data=$("${SESSION_TRACKER}" get)

# Check if there's an active session with content
if [[ "${session_data}" == "{}" ]]; then
    echo "No Leeroy session data to attach" >&2
    exit 0
fi

# Check if any files were modified or prompts logged
files_count=$(echo "${session_data}" | jq '.files_modified | length')
prompts_count=$(echo "${session_data}" | jq '.prompts | length')

if [[ "${files_count}" -eq 0 ]] && [[ "${prompts_count}" -eq 0 ]]; then
    echo "Empty Leeroy session, skipping attestation" >&2
    exit 0
fi

# Format the attestation
format_attestation() {
    local data="$1"
    
    echo "-----BEGIN AI ATTESTATION-----"
    echo "Version: 1.0"
    echo "Tool: $(echo "$data" | jq -r '.tool // "unknown"')/$(echo "$data" | jq -r '.tool_version // "unknown"')"
    echo "Model: $(echo "$data" | jq -r '.model // "unknown"')"
    echo "Session-ID: $(echo "$data" | jq -r '.session_id')"
    echo "Started-At: $(echo "$data" | jq -r '.started_at')"
    echo "Committed-At: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""
    
    # Files section
    if [[ "${files_count}" -gt 0 ]]; then
        echo "Files-Modified:"
        echo "$data" | jq -r '.files_modified[] | "  - \(.path) [\(.type)] @ \(.timestamp)"'
        echo ""
    fi
    
    # Prompts section
    if [[ "${prompts_count}" -gt 0 ]]; then
        echo "Prompts:"
        echo "$data" | jq -r '.prompts[] | "  [\(.timestamp)] \(.text)"'
        echo ""
    fi
    
    echo "Human-Review-Attested: true"
    echo "-----END AI ATTESTATION-----"
}

# Get the commit we're attaching to
commit_sha=$(git rev-parse HEAD)

# Format the attestation
attestation=$(format_attestation "${session_data}")

# Sign the attestation
signed_attestation=$(echo "${attestation}" | "${SIGN_ATTESTATION}" sign)

# Attach as git note
echo "${signed_attestation}" | git notes --ref=leeroy add -F - "${commit_sha}" 2>/dev/null || \
    echo "${signed_attestation}" | git notes --ref=leeroy append -F - "${commit_sha}"

echo "🐔 Leeroy attestation attached to commit ${commit_sha:0:8}" >&2
echo "   At least you have attestation." >&2

# Show a preview
echo "" >&2
echo "Attestation preview:" >&2
echo "${signed_attestation}" | head -20 >&2
if [[ $(echo "${signed_attestation}" | wc -l) -gt 20 ]]; then
    echo "  ... (truncated)" >&2
fi

# Clear the session for next time
"${SESSION_TRACKER}" clear
