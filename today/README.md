# Leeroy - Today Version

**Use it today. No waiting for git/GitHub changes.**

AI attestation embedded directly into commit messages. Works with any git host, any workflow.

## Install

```bash
./install.sh
export PATH="${PATH}:${HOME}/.leeroy/bin"

cd /path/to/your/repo
leeroy install-hooks
```

## How It Works

```bash
# Work with Claude Code, then commit
$ git commit -m "Add feature"

# Attestation is automatically added
$ git log -1
Add feature

---
AI-Assisted: true
AI-Tool: claude-code/1.0.0
AI-Model: claude-sonnet-4-20250514
AI-Session: abc12345
AI-Files: src/feature.py

AI-Prompts:
- [10:30:00] Add a feature that does X
- [10:35:00] Fix the error handling
```

For human-authored commits:

```bash
git commit -m "Fix typo"
leeroy attest-human
```

## Session Management

Sessions track prompts and file modifications. **Use `/clear` between different tasks** to ensure prompts from one task don't appear in commits for another task.

**Sessions are automatically cleared on:**
- `/clear` command in Claude Code
- Starting a new Claude Code session
- Switching git branches

**Sessions persist across:**
- Multiple commits (same prompts appear in each commit within a task)
- Context compaction
- Session resume

**Manual session clear:**
```bash
leeroy clear-session  # Clear before starting a new task
```

**Multi-commit workflow example:**
```bash
# User: "Do A, B, C with individual commits"
# Claude does A
git commit -m "Add A"  # Commit includes prompt
# Claude does B
git commit -m "Add B"  # Commit includes same prompt
# Claude does C
git commit -m "Add C"  # Commit includes same prompt

# Start new task - either:
/clear                   # In Claude Code
leeroy clear-session     # Or manually
```

## Documentation

- [Installation Guide](../docs/installation.md)
- [CLI Reference](../docs/cli-reference.md)
- [GitHub Actions](../docs/github-actions.md)

## Files

```
~/.leeroy/
├── hooks/
│   ├── session-tracker.sh      # Core session tracking
│   ├── capture-prompt.sh       # UserPromptSubmit hook
│   ├── post-tool-use-wrapper.sh # PostToolUse hook
│   └── session-clear.sh        # SessionStart hook (clears on /clear, startup)
├── git-hooks/
│   ├── prepare-commit-msg      # Injects attestation into commit
│   ├── post-commit             # Clears files (prompts persist)
│   └── post-checkout           # Clears session on branch switch
└── bin/
    └── leeroy                  # CLI tool
```
