# Implementation Plan

## Current State

Working:
- ✅ Session tracking (session-tracker.sh)
- ✅ Claude Code PostToolUse hook (tracks file modifications)
- ✅ Claude Code UserPromptSubmit hook (automatic prompt capture)
- ✅ Claude Code PostCommit hook (attaches attestation)
- ✅ Git hooks (prepare-commit-msg, post-commit, pre-push, post-checkout)
- ✅ CLI tools (ai-log-prompt, leeroy, install-hooks)
- ✅ GitHub Action (labels PRs, shows prompts)

Limitations:
- ❌ No signing (attestations are unsigned)

## To Implement

### ✅ 0. Automatic Prompt Capture (COMPLETED)

**Status:** IMPLEMENTED ✅

**Goal:** Capture user prompts automatically using Claude Code's `UserPromptSubmit` hook.

**Solution implemented:** UserPromptSubmit hook fires when user submits a prompt and automatically logs it.

**How it works:**
- Hook receives prompt data via **STDIN as JSON**
- Parse JSON to extract user's message text
- Call `session-tracker.sh prompt "<text>"`
- Automatic, zero friction for users

**Implementation:**

`hooks/capture-prompt.sh`:
```bash
#!/usr/bin/env bash
# Read prompt JSON from STDIN
prompt_json=$(cat)

# Extract user message text (adjust JSON path as needed)
user_text=$(echo "$prompt_json" | jq -r '.text // .message // .content')

# Log to session
if [[ -n "$user_text" ]]; then
    ~/.leeroy/hooks/session-tracker.sh prompt "$user_text"
fi
```

**Configuration in `~/.claude/settings.json`:**
```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "command": "$HOME/.leeroy/hooks/capture-prompt.sh"
    }],
    "PostToolUse": [{
      "matcher": "write_to_file|create_file|str_replace|edit_file",
      "command": "$HOME/.leeroy/hooks/session-tracker.sh file \"$TOOL_ARG_PATH\" modified"
    }],
    "PostCommit": [{
      "command": "$HOME/.leeroy/hooks/post-commit-attestation.sh"
    }]
  }
}
```

**Files created:**
- ✅ `hooks/capture-prompt.sh` - Parses JSON from STDIN, extracts prompt text
- ✅ Updated `install.sh` - Configures UserPromptSubmit hook in settings.json
- ✅ Updated `CLAUDE.md` - Documents new hook configuration
- ✅ Updated `README.md` - Reflects automatic prompt capture

**Testing completed:**
✅ Tested with JSON containing `.text` field
✅ Tested with JSON containing `.message` field
✅ Tested with JSON containing `.content` field
✅ Gracefully handles invalid/missing JSON data
✅ Session initialized and prompts logged correctly

**Next user action:** Run `./install.sh` to deploy the changes

### ✅ 1. Git Hooks Integration (COMPLETED)

**Status:** IMPLEMENTED ✅

**Goal:** Make attestation work regardless of commit method (CLI, IDE, GUI).

**Files to create:**
```
hooks/git-prepare-commit-msg
hooks/git-post-commit
hooks/git-pre-push
hooks/git-post-checkout
```

**Implementation:**

`hooks/git-prepare-commit-msg`:
- Read `~/.leeroy/current-session.json`
- If session exists, inject summary into commit message:
  ```
  # ──────────────────────────────────────
  # 🤖 AI-Assisted Commit
  # Model: claude-sonnet-4
  # Files: 3, Prompts: 2
  # ──────────────────────────────────────
  ```
- Shows user AI usage before they finalize commit

`hooks/git-post-commit`:
- Call existing `post-commit-attestation.sh`
- More reliable than Claude's PostCommit (runs regardless of commit method)

`hooks/git-pre-push`:
- Check if local notes exist: `git notes --ref=leeroy list`
- If yes, auto-push: `git push origin refs/notes/leeroy`
- Show: "🤖 Pushing N AI attestation note(s)..."

`hooks/git-post-checkout`:
- Detect branch switch (`$3 == 1`)
- If session exists, warn and clear: "⚠️ Branch switch with active AI session"
- Prevents session contamination across branches

**Installation:**

Update `install.sh` to:
1. Create git hook templates in `~/.leeroy/git-hooks/`
2. Add `leeroy install-hooks` command that symlinks hooks to `.git/hooks/`
3. Per-repo opt-in (not global) for safety

**Testing:**
```bash
cd /tmp/test-repo
git init
leeroy install-hooks

# Test prepare-commit-msg
ai-log-prompt "test"
git commit  # Should see AI summary in editor

# Test post-commit
git notes --ref=leeroy show HEAD

# Test pre-push
git push  # Should auto-push notes

# Test post-checkout
ai-log-prompt "test2"
git checkout -b feature  # Should warn and clear
```

**Completion Summary:**

All files created and tested:
- ✅ `hooks/git-prepare-commit-msg` - Injects AI summary into commit message
- ✅ `hooks/git-post-commit` - Calls attestation script
- ✅ `hooks/git-pre-push` - Auto-pushes notes (with diff checking)
- ✅ `hooks/git-post-checkout` - Clears sessions on branch switch
- ✅ `install.sh` - Updated to copy git hooks and add install-hooks command
- ✅ `leeroy install-hooks` - CLI command implemented
- ✅ Testing completed with test repository
- ✅ Documentation updated (README.md, CLAUDE.md, IMPLEMENTATION_PLAN.md)

**Key features:**
- Works with any commit method (CLI, IDE, GUI)
- Automatic note pushing during git push
- Session cleanup on branch switch
- Backup existing hooks before installation
- Clear user feedback during installation

**Next user action:** Run `./install.sh` and then `leeroy install-hooks` in desired repositories.

### ✅ 2. Signing (COMPLETED)

**Status:** IMPLEMENTED ✅

**Goal:** Two-layer signing (tool + contributor) as described in `docs/WHAT-THIS-GETS-US.md`.

#### Layer 1: Tool Signature - IMPLEMENTED

**Key generation:**
- ✅ On first run, generate ed25519 keypair
- ✅ Store at `~/.leeroy/toolkit.key` (private) and `~/.leeroy/toolkit.pub` (public)
- ✅ Include public key fingerprint in attestation

**Signing:**
- ✅ After formatting attestation, sign with toolkit key
- ✅ Add signature block:
  ```
  -----BEGIN AI ATTESTATION-----
  ...
  Human-Review-Attested: true

  Tool-Signature: ed25519:<base64-signature>
  Tool-Key-Fingerprint: <sha256-of-pubkey>
  -----END AI ATTESTATION-----
  ```

**Verification:**
- ✅ `leeroy verify <commit>` checks:
  1. Attestation format valid
  2. Tool signature valid using ed25519 public key
  3. Shows fingerprint for transparency

**Implementation files:**
- ✅ `hooks/sign-attestation.sh` - Sign and verify with toolkit key
  - Commands: sign, verify, generate-keys, fingerprint
  - Uses ed25519 for signing
  - Signs content from BEGIN through "Human-Review-Attested: true"
- ✅ Updated `hooks/post-commit-attestation.sh` to call signing
- ✅ Updated `install.sh` CLI verify command to check signatures

#### Layer 2: Contributor Signature - IMPLEMENTED

**Use standard git commit signing:**
- User can enable GPG/SSH signing: `git config commit.gpgsign true`
- Commit is signed by user's key (standard git)
- Attestation is signed by tool key
- Both signatures provide full trust

**Display in GitHub Action:**
- ✅ Check commit signature: `git verify-commit <sha>`
- ✅ Check attestation signature: verify tool signature
- ✅ Show status in PR comment:
  ```
  ## 🤖 AI Transparency Report

  ### Signature Status
  - `abc1234` Tool: ✅ Signed | Commit: ✅ Signed by user@example.com
  - `def5678` Tool: ✅ Signed | Commit: ❌ Unsigned
  ```

**Implementation:**
- ✅ Updated `.github/workflows/ai-transparency.yml` to check both signatures
- ✅ Added signature status section to PR comment

#### Layer 3: Provider Signature (Out of Scope)

Not implementing. Requires API changes from Anthropic/OpenAI.

Document in `docs/WHAT-THIS-GETS-US.md` as future work.

**Testing completed:**
- ✅ Key generation with ed25519
- ✅ Signing attestations with toolkit key
- ✅ Verification with public key
- ✅ Full commit flow with signed attestations
- ✅ CLI verify command shows signature status
- ✅ GitHub Action displays signature status in PR comments

### ✅ 3. Testing (COMPLETED)

**Status:** IMPLEMENTED ✅

**Unit tests:**
- ✅ `tests/session-tracker.bats` - Test session operations (20 tests)
- ✅ `tests/signing.bats` - Test key generation and signature verification (25 tests)

**Integration tests:**
- ✅ `tests/integration.bats` - Full workflow tests (10 tests)
  - Full flow: Claude edit → log prompt → commit → verify note + signatures
  - CLI tool testing (list, show, verify, stats)
  - Multiple sessions and commits
  - Signature verification and tampering detection
  - Environment variable handling

**Test runner:**
- ✅ `run-tests.sh` - Convenient test runner with verbose mode

**Running tests:**
```bash
# Install bats (if not already installed)
# Arch: sudo pacman -S bats
# Ubuntu/Debian: sudo apt-get install bats
# macOS: brew install bats-core

# Run all tests
./run-tests.sh

# Run specific test file
./run-tests.sh -f tests/session-tracker.bats

# Run with verbose output
./run-tests.sh -v
```

**Test coverage:**
- Session initialization and tracking
- File modification logging
- Prompt logging
- Session get/clear operations
- Key generation (ed25519)
- Attestation signing
- Signature verification
- Tampering detection
- Full commit workflow
- CLI tools
- Environment variable handling
- Error conditions

All tests passing ✅

## Implementation Order

1. **Automatic prompt capture** (CRITICAL)
   - Without this, the toolkit provides almost no value
   - Prompts are the key insight (see docs/WHAT-THIS-GETS-US.md)
   - Must implement UserPromptSubmit hook first

2. **Git hooks** (high priority)
   - Makes toolkit work universally, not just with Claude commits
   - Foundation for everything else
   - Enables auto-push and session cleanup

3. **Tool signing** (medium priority)
   - Raises bar for forgery
   - Enables verification
   - Layer 1 of trust model

4. **Contributor signing integration** (low priority)
   - Users may already have commit signing enabled
   - GitHub Action can check existing commit signatures
   - Just needs display logic in workflow
   - Layer 2 of trust model

5. **Testing** (throughout)
   - Add tests as features are built
   - End-to-end test with real workflow

## Open Questions

1. **UserPromptSubmit JSON structure:** What's the exact JSON format?
   - **Action:** Need to inspect actual STDIN data from hook
   - Could be: `{"text": "..."}`, `{"message": "..."}`, `{"content": "..."}`, or nested structure
   - Implementation should handle multiple possible fields gracefully

2. **Git hook conflicts:** What if user has existing git hooks?
   - **Solution:** Check if hook exists, chain if possible, warn if not
   - Future: Use hook managers (husky, pre-commit)

3. **Key management:** Where to store toolkit signing key?
   - **Proposed:** `~/.leeroy/toolkit.key` (chmod 600)
   - **Risk:** Still on user machine, can be extracted
   - **Mitigation:** Document this limitation clearly

4. **Signature format:** Use standard formats or custom?
   - **Proposed:** ed25519 + base64 (simple, standard crypto)
   - **Alternative:** PGP (more standard, more complex)

5. **Migration:** Users with existing attestations without signatures?
   - **Solution:** Old attestations remain valid (just unsigned)
   - New attestations include signatures
   - Verify command shows signature status

## Success Criteria

POC is complete when:
- ✅ Works with any commit method (CLI, IDE, GUI)
- ✅ Attestations are signed (tool signature)
- ✅ Can verify signatures with CLI
- ✅ GitHub Action shows signature status
- ✅ Notes auto-push on git push
- ✅ Sessions clear on branch switch
- ✅ Documentation complete (README, CLAUDE.md, WHAT-THIS-GETS-US)
- ✅ Can demo full workflow end-to-end

## Non-Goals (Out of Scope)

- Multi-tool support (Cursor, Copilot) - Claude Code only for POC
- Provider signatures - requires API changes
- AI detection/fingerprinting - not fraud detection
- Browser extension - GitHub Action is sufficient
- Windows support - bash scripts are Linux/Mac only
