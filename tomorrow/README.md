# Leeroy - Tomorrow Version

**Experimental. Demonstrates what's possible with platform support.**

Uses git notes for rich attestation with cryptographic signatures. Requires ecosystem changes to be practical.

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

# Attestation is attached as a git note
$ git notes --ref=leeroy show HEAD
-----BEGIN AI ATTESTATION-----
Version: 1.0
Tool: claude-code/1.0.0
Model: claude-sonnet-4-20250514
Session-ID: abc12345

Files-Modified:
  - src/feature.py [modified] @ 2024-01-15T10:35:00Z

Prompts:
  [10:30:00] Add a feature that does X
  [10:40:00] Fix the error handling

Tool-Signature: ed25519:base64...
-----END AI ATTESTATION-----

# Notes must be pushed separately
$ git push origin refs/notes/leeroy
```

## Why This Is Experimental

Git notes require:
- Explicit push/fetch of notes refs
- GitHub/GitLab to display notes in UI
- CI systems to fetch notes
- Notes are lost on rebase

**Use the [today version](../today/) for practical use.**

## Additional Commands

```bash
leeroy verify HEAD    # Verify tool signature
leeroy fetch          # Fetch notes from origin
leeroy push           # Push notes to origin
leeroy clear-session  # Clear session before new task
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

## Documentation

- [Installation Guide](../docs/installation.md)
- [CLI Reference](../docs/cli-reference.md)
- [GitHub Actions](../docs/github-actions.md)

## Files

```
~/.leeroy/
├── hooks/
│   ├── session-tracker.sh         # Core session tracking
│   ├── capture-prompt.sh          # UserPromptSubmit hook
│   ├── post-tool-use-wrapper.sh   # PostToolUse hook
│   ├── session-clear.sh           # SessionStart hook (clears on /clear, startup)
│   ├── post-commit-attestation.sh # Creates signed attestation
│   └── sign-attestation.sh        # ed25519 signing
├── git-hooks/
│   ├── prepare-commit-msg         # Shows AI summary before commit
│   ├── post-commit                # Attaches attestation, clears files
│   ├── pre-push                   # Auto-pushes notes
│   └── post-checkout              # Clears session on branch switch
├── bin/
│   └── leeroy                     # CLI tool
└── toolkit.key                    # ed25519 signing key
```
