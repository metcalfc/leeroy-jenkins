#!/usr/bin/env bash
#
# Leeroy Installation Script (Today Version)
# Embeds AI attestation directly into commit messages
#
# No git notes, no separate refs to manage. Just commit messages.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${HOME}/.leeroy"
CLAUDE_SETTINGS="${HOME}/.claude/settings.json"

echo "Installing Leeroy (Today Version)"
echo "AI attestation in commit messages"
echo ""

# Check for required dependencies
check_dependencies() {
    local missing=()

    for cmd in jq openssl git; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing required dependencies: ${missing[*]}"
        echo ""
        echo "Install with your package manager:"
        echo "  macOS:    brew install ${missing[*]}"
        echo "  Ubuntu:   sudo apt-get install ${missing[*]}"
        echo ""
        exit 1
    fi
}

check_dependencies
echo "Dependencies OK"
echo ""

# Create installation directory
echo "Creating installation directory..."
mkdir -p "${INSTALL_DIR}/hooks"
mkdir -p "${INSTALL_DIR}/bin"
mkdir -p "${INSTALL_DIR}/git-hooks"

# Copy hooks
echo "Installing hooks..."
cp "${SCRIPT_DIR}/hooks/"*.sh "${INSTALL_DIR}/hooks/"
chmod +x "${INSTALL_DIR}/hooks/"*.sh

# Copy git hooks
echo "Installing git hooks..."
for hook in "${SCRIPT_DIR}/hooks/git-"*; do
    if [[ -f "${hook}" ]]; then
        cp "${hook}" "${INSTALL_DIR}/git-hooks/"
    fi
done
chmod +x "${INSTALL_DIR}/git-hooks/"* 2>/dev/null || true

# Create the CLI
cat > "${INSTALL_DIR}/bin/leeroy" << 'EOFCLI'
#!/usr/bin/env bash
#
# Leeroy CLI
# Query AI attestations embedded in commit messages

set -euo pipefail

cmd_list() {
    local count="${1:-10}"
    echo "Recent AI-assisted commits:"
    echo ""

    git log -n "${count}" --format="%h %s" --grep="AI-Assisted: true" 2>/dev/null || true
}

cmd_show() {
    local ref="${1:-HEAD}"
    local msg
    msg=$(git log -1 --format="%B" "${ref}" 2>/dev/null)

    if echo "${msg}" | grep -q "AI-Assisted: true"; then
        echo "AI Attestation for $(git rev-parse --short "${ref}"):"
        echo ""
        echo "${msg}" | sed -n '/^---$/,$p'
    elif echo "${msg}" | grep -q "Human-Attested: true"; then
        echo "Human Attestation for $(git rev-parse --short "${ref}"):"
        echo ""
        echo "${msg}" | sed -n '/^---$/,$p'
    else
        echo "No attestation found for ${ref}" >&2
        exit 1
    fi
}

cmd_stats() {
    local total ai_assisted human_attested
    total=$(git rev-list HEAD --count 2>/dev/null || echo 0)
    ai_assisted=$(git log --grep="AI-Assisted: true" --oneline 2>/dev/null | wc -l | tr -d ' ')
    human_attested=$(git log --grep="Human-Attested: true" --oneline 2>/dev/null | wc -l | tr -d ' ')

    echo "Attestation Stats for $(basename "$(git rev-parse --show-toplevel)")"
    echo ""
    echo "Total commits:    ${total}"
    echo "AI-assisted:      ${ai_assisted}"
    echo "Human-attested:   ${human_attested}"
    if [[ ${total} -gt 0 ]]; then
        local ai_pct=$((ai_assisted * 100 / total))
        local human_pct=$((human_attested * 100 / total))
        local attested=$((ai_assisted + human_attested))
        local attested_pct=$((attested * 100 / total))
        echo "Total attested:   ${attested} (${attested_pct}%)"
    fi
}

cmd_attest_human() {
    local ref="${1:-HEAD}"

    # Verify we're in a git repo
    if ! git rev-parse --git-dir &>/dev/null; then
        echo "Error: Not in a git repository" >&2
        exit 1
    fi

    # Check if this is HEAD (we can only amend HEAD)
    local target_sha ref_sha
    target_sha=$(git rev-parse HEAD)
    ref_sha=$(git rev-parse "${ref}" 2>/dev/null) || {
        echo "Error: Invalid ref '${ref}'" >&2
        exit 1
    }

    if [[ "${ref_sha}" != "${target_sha}" ]]; then
        echo "Error: Can only attest HEAD commit (use interactive rebase for older commits)" >&2
        exit 1
    fi

    # Check if already attested
    local msg
    msg=$(git log -1 --format="%B" HEAD)

    if echo "${msg}" | grep -q "AI-Assisted: true"; then
        echo "Error: Commit already has AI attestation" >&2
        exit 1
    fi

    if echo "${msg}" | grep -q "Human-Attested: true"; then
        echo "Error: Commit already has human attestation" >&2
        exit 1
    fi

    # Get author info
    local author_name author_email timestamp
    author_name=$(git config user.name)
    author_email=$(git config user.email)
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Build attestation block
    local attestation
    attestation=$(cat << EOATTEST

---
AI-Assisted: false
Human-Attested: true
Attested-By: ${author_name} <${author_email}>
Attested-At: ${timestamp}
EOATTEST
)

    # Amend the commit with attestation
    local new_msg="${msg}${attestation}"

    git commit --amend -m "${new_msg}" --no-edit --allow-empty-message

    echo "Human attestation added to $(git rev-parse --short HEAD)"
    echo ""
    echo "Attestation:"
    echo "  AI-Assisted: false"
    echo "  Human-Attested: true"
    echo "  Attested-By: ${author_name} <${author_email}>"
    echo "  Attested-At: ${timestamp}"
}

cmd_clear_session() {
    local session_tracker="${HOME}/.leeroy/hooks/session-tracker.sh"
    if [[ -x "${session_tracker}" ]]; then
        "${session_tracker}" clear
        echo "Session cleared. Next commit will start fresh."
    else
        echo "Error: Session tracker not found" >&2
        exit 1
    fi
}

cmd_install_hooks() {
    if ! git rev-parse --git-dir &>/dev/null; then
        echo "Error: Not in a git repository" >&2
        exit 1
    fi

    local git_dir
    git_dir=$(git rev-parse --git-dir)
    local hooks_dir="${git_dir}/hooks"
    mkdir -p "${hooks_dir}"

    local source_dir="${HOME}/.leeroy/git-hooks"
    if [[ ! -d "${source_dir}" ]]; then
        echo "Error: Git hooks not found. Run install.sh first." >&2
        exit 1
    fi

    echo "Installing git hooks..."
    echo ""

    for hook in "${source_dir}"/*; do
        local hook_name
        hook_name=$(basename "${hook}")
        local target_name="${hook_name#git-}"
        local target="${hooks_dir}/${target_name}"

        if [[ -f "${target}" ]]; then
            echo "Backing up existing: ${target_name}"
            cp "${target}" "${target}.backup"
        fi

        ln -sf "${hook}" "${target}"
        echo "Installed: ${target_name}"
    done

    echo ""
    echo "Git hooks installed!"
    echo "Commits will now include AI attestation automatically."
}

cmd_help() {
    cat << EOF
Leeroy CLI
AI attestation embedded in commit messages

Usage: leeroy <command> [args]

Commands:
  list [n]        List recent AI-assisted commits (default: 10)
  show [ref]      Show attestation for a commit (default: HEAD)
  stats           Show attestation statistics
  install-hooks   Install git hooks in current repository
  attest-human    Attest that HEAD commit was human-authored (no AI)
  clear-session   Clear current session (start fresh for next task)
  help            Show this help message

Session Management:
  Sessions are automatically cleared on:
  - /clear command in Claude Code
  - New Claude Code session
  - Git branch switch

  Use 'leeroy clear-session' to manually clear when starting a new task
  without clearing Claude's conversation context.

Examples:
  leeroy install-hooks
  leeroy list 20
  leeroy show abc123
  leeroy stats
  leeroy attest-human    # Add human attestation to last commit
  leeroy clear-session   # Clear session before starting new task
EOF
}

case "${1:-help}" in
    list)          cmd_list "${2:-10}" ;;
    show)          cmd_show "${2:-HEAD}" ;;
    stats)         cmd_stats ;;
    install-hooks) cmd_install_hooks ;;
    attest-human)  cmd_attest_human "${2:-HEAD}" ;;
    clear-session) cmd_clear_session ;;
    help|*)        cmd_help ;;
esac
EOFCLI
chmod +x "${INSTALL_DIR}/bin/leeroy"

echo ""
echo "CLI installed"

# Configure Claude Code hooks
echo ""
echo "Configuring Claude Code integration..."

if [[ -f "${CLAUDE_SETTINGS}" ]]; then
    echo "Found existing Claude Code settings at ${CLAUDE_SETTINGS}"
    echo "Merging Leeroy hooks..."

    # Use jq to merge hooks into existing settings
    tmp=$(mktemp)
    jq --arg capture "${INSTALL_DIR}/hooks/capture-prompt.sh" \
       --arg tooluse "${INSTALL_DIR}/hooks/post-tool-use-wrapper.sh" \
       --arg sessionclear "${INSTALL_DIR}/hooks/session-clear.sh" '
       .hooks.UserPromptSubmit = [{"hooks": [{"type": "command", "command": $capture}]}] |
       .hooks.PostToolUse = [{"hooks": [{"type": "command", "command": $tooluse}]}] |
       .hooks.SessionStart = [{"hooks": [{"type": "command", "command": $sessionclear}]}]
    ' "${CLAUDE_SETTINGS}" > "$tmp" && mv "$tmp" "${CLAUDE_SETTINGS}"

    echo "Hooks merged into ${CLAUDE_SETTINGS}"
else
    echo "Creating Claude Code settings..."
    mkdir -p "${HOME}/.claude"
    cat > "${CLAUDE_SETTINGS}" << EOF
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${INSTALL_DIR}/hooks/capture-prompt.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${INSTALL_DIR}/hooks/post-tool-use-wrapper.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${INSTALL_DIR}/hooks/session-clear.sh"
          }
        ]
      }
    ]
  }
}
EOF
    echo "Created ${CLAUDE_SETTINGS}"
fi

echo ""
echo "================================================"
echo ""
echo "Installation complete!"
echo ""
echo "Add to your shell profile:"
echo ""
echo "  export PATH=\"\${PATH}:${INSTALL_DIR}/bin\""
echo ""
echo "Then install git hooks in your repo:"
echo ""
echo "  cd /path/to/your/repo"
echo "  leeroy install-hooks"
echo ""
echo "That's it! Your commits will now include AI attestation."
echo ""
echo "Example commit message:"
echo "  Add new feature"
echo ""
echo "  ---"
echo "  AI-Assisted: true"
echo "  AI-Tool: claude-code/1.0.0"
echo "  AI-Model: claude-sonnet-4-20250514"
echo "  AI-Session: abc12345"
echo "  AI-Files: src/main.py, tests/test_main.py"
echo "  AI-Prompts: 3"
echo ""
echo "================================================"
