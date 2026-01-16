# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AI Attestation Toolkit - Transparent attribution for AI-assisted code contributions using git notes, hooks, and signatures.

**Core value:** Makes honest AI disclosure easy. See `docs/WHAT-THIS-GETS-US.md` for the full value proposition.

**Not in scope:** Fraud detection, AI detection, preventing forgery. This is about reducing friction for honest contributors.

## Architecture

### Session Tracking
Located in `~/.ai-attestation/`:
- `current-session.json` - Active AI session (prompts, files, timestamps)
- `prompts.log` - Flat log of all prompts

### Hooks
**Claude Code hooks** (`hooks/`):
- `session-tracker.sh` - Manages session JSON (init, log file, log prompt, get, clear)
- `post-commit-attestation.sh` - Formats attestation and attaches as git note
- `sign-attestation.sh` - Signs attestations with ed25519 toolkit key
- `log-prompt.sh` - User-facing wrapper for logging prompts
- `capture-prompt.sh` - Automatic prompt capture via UserPromptSubmit hook

**Git hooks** (implemented):
- `git-prepare-commit-msg` - Show AI summary before commit
- `git-post-commit` - Attach attestation note
- `git-pre-push` - Auto-push notes
- `git-post-checkout` - Clear stale sessions

### CLI Tools
Installed to `~/.ai-attestation/bin/` via `install.sh`:
- `ai-log-prompt` - Log prompts to current session
- `ai-attestation` - Query tool (list, show, stats, verify, fetch, push)

### Attestation Storage
- Stored as **git notes** under `refs/notes/ai-attestation`
- Attached to commit SHAs
- Pushed/fetched independently from commits

### Format
```
-----BEGIN AI ATTESTATION-----
Version: 1.0
Tool: claude-code/<version>
Model: <model-id>
Session-ID: <hex>
Started-At: <timestamp>
Committed-At: <timestamp>

Files-Modified:
  - <path> [modified|created|deleted] @ <timestamp>

Prompts:
  [<timestamp>] <prompt-text>

Human-Review-Attested: true

Tool-Signature: ed25519:<base64-signature>
Tool-Key-Fingerprint: <sha256-of-pubkey>
-----END AI ATTESTATION-----
```

### Signing
Attestations are cryptographically signed with a two-layer approach:

**Layer 1: Tool Signature**
- Attestations are signed with an ed25519 toolkit key
- Key generated on first use: `~/.ai-attestation/toolkit.key`
- Public key fingerprint included in attestation for transparency
- Raises the bar for forgery - can't hand-craft attestations
- Verified with `ai-attestation verify <commit>`

**Layer 2: Contributor Signature**
- Standard git commit signing (GPG/SSH)
- Enable with: `git config commit.gpgsign true`
- Links contributor identity to AI-assisted work
- Shown in GitHub Action PR comments

Together, these provide accountability and authenticity.

## Development Commands

### Build/Test
```bash
# Install toolkit
./install.sh

# Add to PATH
export PATH="${PATH}:${HOME}/.ai-attestation/bin"

# Test session tracking
~/.ai-attestation/hooks/session-tracker.sh init
~/.ai-attestation/hooks/session-tracker.sh file "test.txt" modified
~/.ai-attestation/hooks/session-tracker.sh prompt "test prompt"
~/.ai-attestation/hooks/session-tracker.sh get

# Test attestation
git commit -m "test"
git notes --ref=ai-attestation show HEAD

# Test CLI
ai-attestation list
ai-attestation show HEAD
ai-attestation stats
```

### Key Files

**Installation:**
- `install.sh` - Main installer (copies hooks, creates CLI, configures Claude)

**Session Tracking:**
- `hooks/session-tracker.sh:23-40` - Session initialization with unique ID
- `hooks/session-tracker.sh:43-61` - File modification logging
- `hooks/session-tracker.sh:64-83` - Prompt logging
- `hooks/capture-prompt.sh` - Automatic prompt capture via UserPromptSubmit hook

**Attestation:**
- `hooks/post-commit-attestation.sh:34-62` - Format attestation from session
- `hooks/post-commit-attestation.sh:71-72` - Attach note (add or append)

**Git Hooks:**
- `hooks/git-prepare-commit-msg` - Inject AI summary into commit message
- `hooks/git-post-commit` - Call attestation script after commit
- `hooks/git-pre-push` - Auto-push notes to remote
- `hooks/git-post-checkout` - Clear session on branch switch

**CLI:**
- `install.sh:30-230` - Embedded CLI implementation (includes install-hooks command)

**GitHub Actions:**
- `.github/workflows/ai-transparency.yml:31-66` - Analyze commits for attestations
- `.github/workflows/ai-transparency.yml:152-217` - Post PR comment with details

## Important Implementation Details

### Git Notes Quirks
- Notes stored in `refs/notes/ai-attestation` (separate from commits)
- Must explicitly push: `git push origin refs/notes/ai-attestation`
- Must explicitly fetch: `git fetch origin refs/notes/ai-attestation:refs/notes/ai-attestation`
- `git notes add` fails if note exists; use `git notes append` or handle failure
- Post-commit hook tries `add`, falls back to `append` (line 71-72)

### Session Lifecycle
1. First Claude edit → `PostToolUse` fires → session initialized
2. More edits → append to `files_modified` array
3. User logs prompts → append to `prompts` array
4. Commit → attestation formatted → attached as note → **session cleared**
5. Next Claude edit → new session

**Critical:** Session must be cleared after commit, otherwise next commit gets stale data.

### Claude Code Hook Config
Expected in `~/.claude/settings.json`:
```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "command": "$HOME/.ai-attestation/hooks/capture-prompt.sh"
    }],
    "PostToolUse": [{
      "matcher": "write_to_file|create_file|str_replace|edit_file",
      "command": "$HOME/.ai-attestation/hooks/session-tracker.sh file \"$TOOL_ARG_PATH\" modified"
    }],
    "PostCommit": [{
      "command": "$HOME/.ai-attestation/hooks/post-commit-attestation.sh"
    }]
  }
}
```

Environment variables set by Claude Code:
- `TOOL_ARG_PATH` - File path being modified
- `CLAUDE_CODE_VERSION` - Tool version (optional)
- `CLAUDE_MODEL` - Model ID (optional)

### Dependencies
- `jq` - JSON parsing in session-tracker.sh
- `openssl` - Random session ID generation, ed25519 signing/verification
- `git` 1.6.6+ - Notes support

## Implementation Plan

See `IMPLEMENTATION_PLAN.md` for detailed implementation steps, priorities, and open questions.

## To Be Implemented

### ✅ Priority 0: Automatic Prompt Capture (COMPLETED)

**Status:** IMPLEMENTED

User prompts are now automatically captured via Claude Code's `UserPromptSubmit` hook.

**Implementation:**
- ✅ `hooks/capture-prompt.sh` - Parses JSON from STDIN and logs prompts
- ✅ `install.sh` - Configures UserPromptSubmit hook in `~/.claude/settings.json`
- ✅ Tested with multiple JSON formats (text, message, content fields)
- ✅ Gracefully handles invalid/missing data

**How it works:**
- Hook fires automatically when user submits a prompt to Claude
- Receives prompt data via STDIN as JSON
- Extracts user's message text using jq (tries multiple possible fields)
- Calls `session-tracker.sh prompt "<text>"` automatically
- Zero friction for users - no manual logging required

### ✅ Priority 1: Git Hooks Integration (COMPLETED)

**Status:** IMPLEMENTED

Git hooks now enable attestation regardless of commit method (CLI, IDE, GUI), not just through Claude Code.

**Implementation:**
- ✅ `hooks/git-prepare-commit-msg` - Injects AI summary into commit message editor
- ✅ `hooks/git-post-commit` - Calls post-commit-attestation.sh reliably
- ✅ `hooks/git-pre-push` - Auto-pushes attestation notes during git push
- ✅ `hooks/git-post-checkout` - Clears sessions on branch switch
- ✅ `install.sh` - Copies git hooks to `~/.ai-attestation/git-hooks/`
- ✅ `ai-attestation install-hooks` - Per-repo installation command
- ✅ Tested with test repository

**How it works:**
- Hooks installed per-repository via `ai-attestation install-hooks`
- Symlinks created in `.git/hooks/` pointing to `~/.ai-attestation/git-hooks/`
- Works with any commit method: CLI `git commit`, IDE integrations, GUI clients
- Automatic note pushing during `git push` (no manual push needed)
- Session cleanup prevents contamination across branches

**Usage:**
```bash
cd /path/to/your/repo
ai-attestation install-hooks
```

### ✅ Priority 2: Signing (COMPLETED)

**Status:** IMPLEMENTED

Two-layer signature system as described in `docs/WHAT-THIS-GETS-US.md`:

**Layer 1: Tool Signature** ✅
- Attestations signed with ed25519 toolkit key
- Key generated automatically on first use
- Stored at `~/.ai-attestation/toolkit.key` (private)
- Public key fingerprint included in attestation
- Raises bar for forgery - can't hand-craft attestations

**Layer 2: Contributor Signature** ✅
- Standard git commit signing (GPG/SSH)
- Enable with: `git config commit.gpgsign true`
- Links contributor identity to AI-assisted work
- Both signatures checked and displayed

**Implementation:**
- ✅ `hooks/sign-attestation.sh` - Sign and verify with toolkit key
- ✅ Updated `post-commit-attestation.sh` to sign before attaching
- ✅ `ai-attestation verify` checks both tool and commit signatures
- ✅ GitHub Action shows signature status in PR comments

**Testing completed:**
- ✅ Key generation with ed25519
- ✅ Signing and verification
- ✅ Full commit flow with signed attestations
- ✅ CLI verify command
- ✅ GitHub Action signature display

### Out of Scope

**Multi-Tool Support:** Out of scope for POC. Focus on Claude Code only.

**Provider Signatures (Layer 3):** Requires API changes from Anthropic/OpenAI. Future work.

## Testing Strategy

1. **Unit**: Test session-tracker.sh operations in isolation
2. **Integration**: Test full flow (Claude edit → commit → note attached)
3. **End-to-end**: Test with actual Claude Code + git workflow
4. **GitHub Action**: Test PR labeling with `act` or real PR
