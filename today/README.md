# Leeroy - Today Version

**Use it today. No waiting for git/GitHub changes.**

No git notes, no separate refs, no extra pushes. Just commit messages.

## What is this?

AI attestation embedded directly into commit messages using standard git trailers. Works with any git host, any git UI, any workflow.

## Quick Start

```bash
cd today
./install.sh

# Add to your PATH
export PATH="${PATH}:${HOME}/.leeroy/bin"

# Install git hooks in your repo
cd /path/to/your/repo
leeroy install-hooks
```

That's it. Your commits will now include AI attestation automatically.

## How it works

```
# Make changes with Claude Code...
# Then commit normally
$ git commit -m "Add feature"

# Attestation is automatically added to the commit message
$ git log -1
Add feature

---
AI-Assisted: true
AI-Tool: claude-code/1.0.0
AI-Model: claude-sonnet-4-20250514
AI-Session: abc12345
AI-Started: 2024-01-15T10:30:00Z
AI-Files: src/feature.py

AI-Prompts:
- [10:30:00] Add a feature that does X
- [10:35:00] Fix the error handling

# Push works normally - attestation travels with the commit
$ git push
```

## Attestation format

Uses standard git trailer format with full prompt text:

```
Your commit message here

---
AI-Assisted: true
AI-Tool: claude-code/1.0.0
AI-Model: claude-sonnet-4-20250514
AI-Session: 8a7b6c5d
AI-Started: 2024-01-15T10:30:00Z
AI-Files: src/main.py, src/utils.py

AI-Prompts:
- [10:30:00] Add a feature that does X
- [10:35:00] Fix the error handling
- [10:40:00] Add tests for the edge cases
```

Full prompt text is preserved, including newlines.

## CLI commands

```bash
leeroy list           # List AI-assisted commits
leeroy show HEAD      # Show attestation for a commit
leeroy stats          # Show repo statistics
leeroy install-hooks  # Install git hooks in current repo
```

## Trade-offs vs Tomorrow version

| Feature | Today (commit msg) | Tomorrow (git notes) |
|---------|-------------------|----------------------|
| Works now | Yes | Requires ecosystem changes |
| Portability | Travels with commits | Requires separate push/fetch |
| Complexity | Simple | More complex |
| Full prompt text | Yes | Yes |
| Tool signatures | No | Yes |
| Commit message size | Larger | Unchanged |

## Requirements

- `jq` - JSON processing
- `openssl` - Session ID generation
- `git`

## Files

```
~/.leeroy/
  hooks/
    session-tracker.sh       # Track AI session
    capture-prompt.sh        # Auto-capture prompts
    post-tool-use-wrapper.sh # Track file modifications
  git-hooks/
    git-prepare-commit-msg   # Embed attestation
    git-post-commit          # Clear session
    git-post-checkout        # Clear on branch switch
  bin/
    leeroy                   # CLI tool
```
