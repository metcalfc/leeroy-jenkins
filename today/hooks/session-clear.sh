#!/usr/bin/env bash
#
# Leeroy Session Clear Hook
# Called by Claude Code's SessionStart hook
#
# Clears the session on:
#   - startup: Fresh Claude Code session (new context)
#   - clear: User ran /clear (explicit context clear)
#
# Does NOT clear on:
#   - resume: Resuming previous session (context preserved)
#   - compact: Context compaction (context preserved, just compressed)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_TRACKER="${SCRIPT_DIR}/session-tracker.sh"

# Read JSON from STDIN
input=$(cat)

# Check the source of the SessionStart event
source=""
if [[ -n "${input}" ]]; then
    source=$(echo "${input}" | jq -r '.source // empty' 2>/dev/null || true)
fi

# Clear session on startup or explicit /clear
case "${source}" in
    startup)
        "${SESSION_TRACKER}" clear 2>/dev/null || true
        echo "Session cleared (new Claude session)" >&2
        ;;
    clear)
        "${SESSION_TRACKER}" clear 2>/dev/null || true
        echo "Session cleared (/clear)" >&2
        ;;
    resume|compact)
        # Don't clear - context is preserved
        ;;
esac
