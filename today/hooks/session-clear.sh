#!/usr/bin/env bash
#
# Leeroy - Session Clear Hook
# Called by Claude Code's SessionStart hook
#
# Clears session on:
#   - startup: Fresh Claude Code session
#   - clear:   User ran /clear
#
# Does NOT clear on:
#   - resume:  Resuming previous session
#   - compact: Context compaction

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly SESSION_TRACKER="${SCRIPT_DIR}/session-tracker.sh"

# Read JSON from stdin
input=$(cat)

# Extract the source of the SessionStart event
source=""
[[ -n "${input}" ]] && source=$(echo "${input}" | jq -r '.source // empty' 2>/dev/null || true)

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

exit 0
