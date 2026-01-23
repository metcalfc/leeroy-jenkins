#!/usr/bin/env bash
#
# Leeroy Uninstall Script
# Removes Leeroy toolkit and cleans up Claude Code hooks
#
# Can be run from anywhere - no assumptions about script location

set -euo pipefail

INSTALL_DIR="${HOME}/.leeroy"
CLAUDE_SETTINGS="${HOME}/.claude/settings.json"

echo "Leeroy Uninstaller"
echo ""

# Track what we've done
removed_install_dir=false
removed_hooks=false
warned_git_hooks=false

# Remove installation directory
if [[ -d "${INSTALL_DIR}" ]]; then
    echo "Removing ${INSTALL_DIR}..."
    rm -rf "${INSTALL_DIR}"
    removed_install_dir=true
    echo "  Removed installation directory"
else
    echo "Installation directory not found (${INSTALL_DIR})"
fi

# Remove hooks from Claude Code settings
if [[ -f "${CLAUDE_SETTINGS}" ]]; then
    echo ""
    echo "Cleaning Claude Code settings..."

    # Check if our hooks are present
    if jq -e '.hooks.UserPromptSubmit[0].hooks[0].command | contains(".leeroy")' "${CLAUDE_SETTINGS}" &>/dev/null || \
       jq -e '.hooks.PostToolUse[0].hooks[0].command | contains(".leeroy")' "${CLAUDE_SETTINGS}" &>/dev/null || \
       jq -e '.hooks.SessionStart[0].hooks[0].command | contains(".leeroy")' "${CLAUDE_SETTINGS}" &>/dev/null; then

        # Remove leeroy hooks while preserving other settings
        tmp=$(mktemp)
        jq 'del(.hooks.UserPromptSubmit) | del(.hooks.PostToolUse) | del(.hooks.SessionStart) | if .hooks == {} then del(.hooks) else . end' \
            "${CLAUDE_SETTINGS}" > "$tmp" && mv "$tmp" "${CLAUDE_SETTINGS}"

        removed_hooks=true
        echo "  Removed Leeroy hooks from settings"

        # Check if settings file is now empty or just {}
        if [[ $(jq 'keys | length' "${CLAUDE_SETTINGS}") -eq 0 ]]; then
            rm "${CLAUDE_SETTINGS}"
            echo "  Removed empty settings file"
        fi
    else
        echo "  No Leeroy hooks found in settings"
    fi
else
    echo ""
    echo "Claude Code settings not found (${CLAUDE_SETTINGS})"
fi

# Warn about git hooks in repositories
echo ""
echo "================================================"
echo ""

if $removed_install_dir || $removed_hooks; then
    echo "Uninstall complete!"
else
    echo "Nothing to uninstall."
fi

echo ""
echo "NOTE: Git hooks installed in repositories are NOT automatically removed."
echo ""
echo "If you ran 'leeroy install-hooks' in any repositories, the git hooks"
echo "are now broken symlinks pointing to the removed installation."
echo ""
echo "To clean up a repository's git hooks:"
echo ""
echo "  cd /path/to/repo"
echo "  rm -f .git/hooks/prepare-commit-msg"
echo "  rm -f .git/hooks/post-commit"
echo "  rm -f .git/hooks/pre-push"
echo "  rm -f .git/hooks/post-checkout"
echo ""
echo "Or restore from backups if they exist:"
echo ""
echo "  mv .git/hooks/prepare-commit-msg.backup .git/hooks/prepare-commit-msg"
echo "  # etc."
echo ""
echo "================================================"
