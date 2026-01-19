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
    else
        echo "No AI attestation found for ${ref}" >&2
        exit 1
    fi
}

cmd_stats() {
    local total ai_assisted
    total=$(git rev-list HEAD --count 2>/dev/null || echo 0)
    ai_assisted=$(git log --grep="AI-Assisted: true" --oneline 2>/dev/null | wc -l | tr -d ' ')

    echo "AI Attestation Stats for $(basename "$(git rev-parse --show-toplevel)")"
    echo ""
    echo "Total commits: ${total}"
    echo "AI-assisted:   ${ai_assisted}"
    if [[ ${total} -gt 0 ]]; then
        local pct=$((ai_assisted * 100 / total))
        echo "Percentage:    ${pct}%"
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
  help            Show this help message

Examples:
  leeroy install-hooks
  leeroy list 20
  leeroy show abc123
  leeroy stats
EOF
}

case "${1:-help}" in
    list)          cmd_list "${2:-10}" ;;
    show)          cmd_show "${2:-HEAD}" ;;
    stats)         cmd_stats ;;
    install-hooks) cmd_install_hooks ;;
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
    echo ""
    echo "Add these hooks to your settings.json:"
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
    ]
  }
}
EOF
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
