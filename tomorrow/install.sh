#!/usr/bin/env bash
#
# Leeroy Installation Script
# Sets up hooks for Claude Code and git

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${HOME}/.leeroy"
CLAUDE_SETTINGS="${HOME}/.claude/settings.json"

# Check for required dependencies
check_dependencies() {
    local missing=()

    # Check for required commands
    for cmd in jq openssl git; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "❌ Missing required dependencies: ${missing[*]}"
        echo ""
        echo "Install with your package manager:"
        echo ""
        echo "  Arch/Omarchy:    sudo pacman -S ${missing[*]}"
        echo "  Ubuntu/Debian:   sudo apt-get install ${missing[*]}"
        echo "  Fedora/RHEL:     sudo dnf install ${missing[*]}"
        echo "  macOS:           brew install ${missing[*]}"
        echo ""
        exit 1
    fi

    # Check if openssl supports ed25519
    if ! openssl list -public-key-algorithms 2>/dev/null | grep -q "ED25519"; then
        echo "⚠️  Warning: Your OpenSSL version may not support ed25519"
        echo "   Signing features may not work properly"
        echo "   Consider upgrading OpenSSL to version 1.1.1 or later"
        echo ""
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
        echo ""
    fi
}

echo "🔧 Installing Leeroy Toolkit"
echo ""

# Check dependencies before proceeding
check_dependencies

echo "✓ All dependencies found"
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
cp "${SCRIPT_DIR}/hooks/git-"* "${INSTALL_DIR}/git-hooks/" 2>/dev/null || true
chmod +x "${INSTALL_DIR}/git-hooks/"* 2>/dev/null || true

# Create convenience symlinks in bin
ln -sf "${INSTALL_DIR}/hooks/log-prompt.sh" "${INSTALL_DIR}/bin/leeroy-log"
ln -sf "${INSTALL_DIR}/hooks/session-tracker.sh" "${INSTALL_DIR}/bin/leeroy-session"

# Create the query CLI
cat > "${INSTALL_DIR}/bin/leeroy" << 'EOFCLI'
#!/usr/bin/env bash
#
# Leeroy Query CLI
# Query and verify Leeroy attestations in git history

set -euo pipefail

ATTESTATION_REF="refs/notes/leeroy"

cmd_list() {
    local count="${1:-10}"
    echo "Recent commits with Leeroy attestation:"
    echo ""

    git log --notes=leeroy -n "${count}" --format="%h %s" 2>/dev/null | while read -r line; do
        sha="${line%% *}"
        if git notes --ref=leeroy show "${sha}" &>/dev/null; then
            echo "✓ ${line}"
        fi
    done
}

cmd_show() {
    local ref="${1:-HEAD}"
    local sha
    sha=$(git rev-parse "${ref}")

    if git notes --ref=leeroy show "${sha}" &>/dev/null; then
        echo "Leeroy Attestation for ${sha:0:8}:"
        echo ""
        git notes --ref=leeroy show "${sha}"
    else
        echo "No Leeroy attestation found for ${ref}" >&2
        exit 1
    fi
}

cmd_stats() {
    local total attested
    total=$(git rev-list HEAD --count 2>/dev/null || echo 0)

    # Count commits with attestations
    attested=0
    while read -r sha; do
        if git notes --ref=leeroy show "${sha}" &>/dev/null; then
            ((attested++)) || true
        fi
    done < <(git rev-list HEAD 2>/dev/null)

    echo "Leeroy Attestation Stats for $(basename "$(git rev-parse --show-toplevel)")"
    echo ""
    echo "Total commits: ${total}"
    echo "Leeroy-attested:   ${attested}"
    if [[ ${total} -gt 0 ]]; then
        local pct=$((attested * 100 / total))
        echo "Percentage:    ${pct}%"
    fi
}

cmd_verify() {
    local ref="${1:-HEAD}"
    local sha
    sha=$(git rev-parse "${ref}")

    if ! git notes --ref=leeroy show "${sha}" &>/dev/null; then
        echo "✗ No attestation found for ${ref}" >&2
        exit 1
    fi

    local attestation
    attestation=$(git notes --ref=leeroy show "${sha}")

    # Basic structure verification
    if echo "${attestation}" | grep -q "BEGIN AI ATTESTATION" && \
       echo "${attestation}" | grep -q "END AI ATTESTATION"; then
        echo "✓ Valid attestation structure"
    else
        echo "✗ Invalid attestation structure" >&2
        exit 1
    fi

    # Check for tool signature
    if echo "${attestation}" | grep -q "^Tool-Signature:"; then
        echo -n "  "
        if echo "${attestation}" | "${HOME}/.leeroy/hooks/sign-attestation.sh" verify; then
            # Signature verification succeeded, message already printed
            true
        else
            echo "  ⚠️  Tool signature verification failed"
        fi
    else
        echo "  ⚠️  No tool signature (unsigned attestation)"
    fi

    # Check for git commit signature
    echo -n "  "
    if git verify-commit "${sha}" &>/dev/null; then
        local signer
        signer=$(git show -s --format='%GS' "${sha}")
        echo "✓ Commit signed by: ${signer}"
    else
        echo "⚠️  Commit not signed"
    fi

    # Extract and display key fields
    echo ""
    echo "Attestation Details:"
    echo "${attestation}" | grep -E "^(Tool|Model|Session-ID|Started-At|Human-Review):" | sed 's/^/  /'

    # Count prompts
    local prompt_count
    prompt_count=$(echo "${attestation}" | grep -c "^\s*\[.*\]" || true)
    echo "  Prompts logged: ${prompt_count}"
}

cmd_fetch() {
    echo "Fetching Leeroy attestation notes from origin..."
    git fetch origin "+${ATTESTATION_REF}:${ATTESTATION_REF}" 2>/dev/null || {
        echo "No attestation notes found on origin (this is normal for new repos)"
    }
}

cmd_push() {
    echo "Pushing Leeroy attestation notes to origin..."
    git push origin "${ATTESTATION_REF}" || {
        echo "Failed to push attestation notes" >&2
        exit 1
    }
    echo "✓ Notes pushed"
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
    # Check if we're in a git repo
    if ! git rev-parse --git-dir &>/dev/null; then
        echo "Error: Not in a git repository" >&2
        exit 1
    fi

    local git_dir
    git_dir=$(git rev-parse --git-dir)
    local hooks_dir="${git_dir}/hooks"

    # Ensure hooks directory exists
    mkdir -p "${hooks_dir}"

    local source_dir="${HOME}/.leeroy/git-hooks"
    if [[ ! -d "${source_dir}" ]]; then
        echo "Error: Git hooks not found at ${source_dir}" >&2
        echo "Run the installation script first: ./install.sh" >&2
        exit 1
    fi

    echo "Installing git hooks to ${hooks_dir}..."
    echo ""

    local installed=0
    local skipped=0

    for hook in "${source_dir}"/*; do
        local hook_name
        hook_name=$(basename "${hook}")
        # Remove 'git-' prefix to get actual hook name
        local target_name="${hook_name#git-}"
        local target="${hooks_dir}/${target_name}"

        if [[ -f "${target}" ]]; then
            echo "⚠️  Hook exists: ${target_name}"
            echo "   Backing up to ${target_name}.backup"
            cp "${target}" "${target}.backup"
        fi

        # Create symlink
        ln -sf "${hook}" "${target}"
        echo "✓ Installed: ${target_name}"
        installed=$((installed + 1))
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✓ Installed ${installed} git hooks"
    echo ""
    echo "Git hooks enabled:"
    echo "  • prepare-commit-msg - Shows AI summary before commit"
    echo "  • post-commit        - Attaches attestation to commit"
    echo "  • pre-push           - Auto-pushes attestation notes"
    echo "  • post-checkout      - Clears sessions on branch switch"
    echo ""
    echo "Now commits from any tool (CLI, IDE, GUI) will be attested!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

cmd_help() {
    cat << EOF
Leeroy CLI
At least you have attestation.

Usage: leeroy <command> [args]

Commands:
  list [n]          List recent commits with Leeroy attestation (default: 10)
  show [ref]        Show attestation for a commit (default: HEAD)
  stats             Show attestation statistics for the repo
  verify [ref]      Verify attestation structure (default: HEAD)
  fetch             Fetch attestation notes from origin
  push              Push attestation notes to origin
  install-hooks     Install git hooks in current repository
  clear-session     Clear current session (start fresh for next task)
  help              Show this help message

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
  leeroy verify HEAD~3
  leeroy stats
  leeroy clear-session   # Clear session before starting new task
EOF
}

# Main dispatch
case "${1:-help}" in
    list)          cmd_list "${2:-10}" ;;
    show)          cmd_show "${2:-HEAD}" ;;
    stats)         cmd_stats ;;
    verify)        cmd_verify "${2:-HEAD}" ;;
    fetch)         cmd_fetch ;;
    push)          cmd_push ;;
    install-hooks) cmd_install_hooks ;;
    clear-session) cmd_clear_session ;;
    help|*)        cmd_help ;;
esac
EOFCLI
chmod +x "${INSTALL_DIR}/bin/leeroy"

echo ""
echo "✓ CLI tools installed"

# Configure Claude Code hooks (if Claude Code is installed)
echo ""
echo "Configuring Claude Code integration..."

if [[ -f "${CLAUDE_SETTINGS}" ]]; then
    echo "Found existing Claude Code settings at ${CLAUDE_SETTINGS}"
    echo ""
    echo "Add the following hooks to your settings.json manually:"
    echo ""
    cat << EOF
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
else
    echo "Claude Code settings not found. Creating..."
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
    echo "✓ Created ${CLAUDE_SETTINGS}"
fi

# Add to PATH suggestion
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🐔 Installation complete!"
echo "   At least you'll have attestation."
echo ""
echo "Add to your shell profile (.bashrc, .zshrc, etc.):"
echo ""
echo "  export PATH=\"\${PATH}:${INSTALL_DIR}/bin\""
echo ""
echo "Then you can use:"
echo ""
echo "  leeroy-log \"your prompt here\"   # Log a prompt"
echo "  leeroy list                      # List attested commits"
echo "  leeroy show                      # Show attestation for HEAD"
echo "  leeroy stats                     # Repo statistics"
echo ""
echo "Install git hooks (per repository):"
echo "  cd /path/to/your/repo"
echo "  leeroy install-hooks"
echo ""
echo "  This enables:"
echo "  • AI summary in commit messages"
echo "  • Automatic attestation attachment"
echo "  • Auto-push of attestation notes"
echo "  • Session cleanup on branch switch"
echo ""
echo "Prompt logging:"
echo "  • Prompts are automatically captured when submitted to Claude Code"
echo "  • For manual logging: ai-log-prompt \"your prompt\""
echo "  • Attestations are automatically attached to commits"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
