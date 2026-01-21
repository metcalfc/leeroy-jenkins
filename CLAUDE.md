# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Leeroy Toolkit - Transparent attribution for AI-assisted code contributions.

**Core value:** Makes honest AI disclosure easy. See `docs/WHAT-THIS-GETS-US.md` for the full value proposition.

**Not in scope:** Fraud detection, AI detection, preventing forgery. This is about reducing friction for honest contributors.

## Repository Structure

The toolkit has **two versions** - pick one:

```
leeroy-jenkins/
  README.md              # Overview comparing both versions
  docs/                  # Value proposition documentation

  today/                 # RECOMMENDED - works now
    install.sh           # Installs to ~/.leeroy
    README.md
    hooks/               # Session tracking + git hooks

  tomorrow/              # Experimental - git notes version
    install.sh           # Installs to ~/.leeroy
    README.md
    hooks/               # Full attestation with signing
    tests/               # Test suite
```

### Today Version (Recommended)

Embeds AI attestation directly into commit messages. Works with any git host.

**Attestation format:**
```
Your commit message

---
AI-Assisted: true
AI-Tool: claude-code/1.0.0
AI-Model: claude-sonnet-4-20250514
AI-Session: abc12345
AI-Started: 2024-01-15T10:30:00Z
AI-Files: src/main.py, src/utils.py

AI-Prompts:
- [10:30:00] Add a feature that does X
- [10:35:00] Fix the error handling
```

**Key files:**
- `today/install.sh` - Main installer
- `today/hooks/session-tracker.sh` - Track AI sessions
- `today/hooks/capture-prompt.sh` - Auto-capture prompts via UserPromptSubmit
- `today/hooks/post-tool-use-wrapper.sh` - Track file modifications
- `today/hooks/session-clear.sh` - Clear session on /clear or startup (SessionStart hook)
- `today/hooks/git-prepare-commit-msg` - Embed attestation in commit message
- `today/hooks/git-post-commit` - Clear files after commit (prompts persist)
- `today/hooks/git-post-checkout` - Clear session on branch switch

### Tomorrow Version (Experimental)

Uses git notes for rich attestation with cryptographic signatures. Requires ecosystem changes to be practical.

**Attestation format:**
```
-----BEGIN AI ATTESTATION-----
Version: 1.0
Tool: claude-code/1.0.0
Model: claude-sonnet-4-20250514
Session-ID: abc12345
...
Tool-Signature: ed25519:base64...
-----END AI ATTESTATION-----
```

**Additional files:**
- `tomorrow/hooks/post-commit-attestation.sh` - Format and attach git note
- `tomorrow/hooks/sign-attestation.sh` - ed25519 signing
- `tomorrow/hooks/git-pre-push` - Auto-push notes
- `tomorrow/tests/` - Test suite with bats

## Session Tracking

Both versions use the same session tracking mechanism.

**Location:** `~/.leeroy/`
- `sessions/<hash>.json` - Per-repo session files (hash of git root path)
- `prompts.log` - Flat log of all prompts (global)

**Multi-repo support:**
- Each repository/worktree gets its own session file
- Multiple simultaneous Claude instances in different repos are supported
- Git worktrees are treated as separate repos (each gets its own session)
- Session isolation is based on `git rev-parse --show-toplevel`

**Session lifecycle:**
1. First Claude edit → `PostToolUse` fires → session initialized
2. More edits → append to `files_modified` array
3. Prompts captured automatically via `UserPromptSubmit` hook
4. Commit → attestation attached → **files cleared, prompts persist**
5. More commits in same task → same prompts in each commit
6. `/clear` or branch switch → **full session cleared**

**When sessions are cleared:**
- `/clear` command in Claude Code (via SessionStart hook)
- New Claude Code session/startup (via SessionStart hook)
- Git branch switch (via git post-checkout hook)
- Manual: `leeroy clear-session`

**When sessions are NOT cleared:**
- Context compaction (prompts remain relevant)
- Session resume (context preserved)
- After commit (only files cleared, prompts persist for multi-commit workflows)

**Important:** Use `/clear` between logical tasks. If you work on Task A, then Task B without `/clear`, Task B's commits will include Task A's prompts.

## Development Commands

### Install and Test (Today Version)

```bash
cd today
./install.sh

export PATH="${PATH}:${HOME}/.leeroy/bin"

# Install git hooks in a repo
cd /path/to/repo
leeroy install-hooks

# Test session tracking
~/.leeroy/hooks/session-tracker.sh init
~/.leeroy/hooks/session-tracker.sh file "test.txt" modified
~/.leeroy/hooks/session-tracker.sh prompt "test prompt"
~/.leeroy/hooks/session-tracker.sh get
~/.leeroy/hooks/session-tracker.sh path  # Show which session file is used

# Test CLI
leeroy list
leeroy show HEAD
leeroy stats
leeroy session  # Show current session info and file path
```

### Install and Test (Tomorrow Version)

```bash
cd tomorrow
./install.sh

export PATH="${PATH}:${HOME}/.leeroy/bin"

cd /path/to/repo
leeroy install-hooks

# Test with git notes
git commit -m "test"
git notes --ref=leeroy show HEAD

# Run tests
./run-tests.sh
```

## Claude Code Hook Config

Both versions configure these hooks in `~/.claude/settings.json`:

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
    }],
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "$HOME/.leeroy/hooks/session-clear.sh"
      }]
    }]
  }
}
```

**How metadata is captured:**
- `post-tool-use-wrapper.sh` reads JSON from stdin (includes transcript_path)
- Extracts model from transcript file
- Gets Claude Code version: `claude --version`
- Calls `session-tracker.sh` with metadata

**How session clearing works:**
- `session-clear.sh` receives SessionStart events with a `source` field
- Clears session on `source: "startup"` (new Claude session) or `source: "clear"` (/clear command)
- Does NOT clear on `source: "resume"` or `source: "compact"` (context preserved)

## Dependencies

- `jq` - JSON parsing
- `openssl` - Session ID generation (and ed25519 signing for tomorrow version)
- `git`

## Key Differences Between Versions

| Aspect | Today | Tomorrow |
|--------|-------|----------|
| Storage | Commit message | Git notes |
| Portability | Travels with commits | Requires separate push |
| Full prompts | Yes | Yes |
| Signatures | No | Yes (ed25519) |
| Survives rebase | Yes | No |
| Complexity | Simple | More complex |

## Implementation Status

Both versions are complete and functional:

- ✅ Automatic prompt capture via UserPromptSubmit hook
- ✅ File modification tracking via PostToolUse hook
- ✅ Git hooks for any commit method (CLI, IDE, GUI)
- ✅ CLI tools (list, show, stats, session, install-hooks, clear-session)
- ✅ Session management via SessionStart hook (/clear, startup)
- ✅ Branch switch detection via git post-checkout hook
- ✅ Multi-commit workflow support (prompts persist across commits)
- ✅ Multi-repo/worktree support (separate sessions per repo)

Tomorrow version additionally has:
- ✅ Cryptographic signing (ed25519)
- ✅ Signature verification
- ✅ GitHub Action for PR labeling
- ✅ Test suite

## Testing (Tomorrow Version Only)

```bash
cd tomorrow

# Run all tests
./run-tests.sh

# Run specific test file
./run-tests.sh -f tests/session-tracker.bats
./run-tests.sh -f tests/signing.bats
./run-tests.sh -f tests/integration.bats
```

See `tomorrow/IMPLEMENTATION_PLAN.md` for detailed implementation notes.
