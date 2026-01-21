# Installation

## Today Version (Recommended)

The today version embeds attestation directly in commit messages. No ecosystem changes required.

### Install

```bash
cd today
./install.sh
```

This will:
1. Create `~/.leeroy/` directory with hooks and CLI
2. Configure Claude Code hooks in `~/.claude/settings.json`

### Add to PATH

Add to your shell profile (`.bashrc`, `.zshrc`, etc.):

```bash
export PATH="${PATH}:${HOME}/.leeroy/bin"
```

### Enable in a Repository

```bash
cd /path/to/your/repo
leeroy install-hooks
```

This installs git hooks that automatically add attestation to commits made during AI sessions.

### Verify Installation

```bash
# Check CLI is available
leeroy help

# Check hooks are installed
ls -la .git/hooks/
```

### How It Works

1. **UserPromptSubmit hook** - Captures prompts you send to Claude
2. **PostToolUse hook** - Tracks files modified by Claude
3. **prepare-commit-msg hook** - Embeds attestation in commit message
4. **post-commit hook** - Clears session after commit

---

## Tomorrow Version (Experimental)

The tomorrow version uses git notes with cryptographic signatures. Requires manual note pushing and ecosystem support.

### Install

```bash
cd tomorrow
./install.sh
```

### Enable in a Repository

```bash
cd /path/to/your/repo
leeroy install-hooks
```

### Pushing Notes

Git notes must be pushed separately:

```bash
git push origin refs/notes/leeroy
```

Or use the CLI:

```bash
leeroy push
```

### Fetching Notes

To see attestations from others:

```bash
git fetch origin refs/notes/leeroy:refs/notes/leeroy
```

Or use the CLI:

```bash
leeroy fetch
```

---

## Requirements

| Dependency | Purpose | Install |
|------------|---------|---------|
| `jq` | JSON processing | `brew install jq` / `apt install jq` |
| `openssl` | Session ID generation | Usually pre-installed |
| `git` | Version control | Usually pre-installed |

## Files Created

```
~/.leeroy/
├── hooks/
│   ├── session-tracker.sh       # Track AI sessions
│   ├── capture-prompt.sh        # Capture prompts (UserPromptSubmit)
│   └── post-tool-use-wrapper.sh # Track file modifications
├── git-hooks/
│   ├── prepare-commit-msg       # Embed attestation
│   ├── post-commit              # Clear session
│   └── post-checkout            # Clear on branch switch
└── bin/
    └── leeroy                   # CLI tool
```

## Claude Code Settings

The installer adds hooks to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "hooks": [{
        "type": "command",
        "command": "$HOME/.leeroy/hooks/capture-prompt.sh"
      }]
    }],
    "PostToolUse": [{
      "hooks": [{
        "type": "command",
        "command": "$HOME/.leeroy/hooks/post-tool-use-wrapper.sh"
      }]
    }]
  }
}
```

## Uninstall

```bash
# Remove installation directory
rm -rf ~/.leeroy

# Remove hooks from Claude settings (edit manually)
# Remove hooks from repos (delete .git/hooks/prepare-commit-msg, etc.)
```
