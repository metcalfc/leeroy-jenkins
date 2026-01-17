# Leeroy

**Don't Leeroy the open source ecosystem. At least you'll have attestation.**

Transparent attribution for AI-assisted code contributions.

![Leeroy Demo](demo.gif)

---

## ⚠️ PROOF OF CONCEPT - NOT PRODUCTION READY

This is a **demonstration** of what transparent AI attribution could look like with proper tooling and platform support.

**Critical Limitation:** Git notes are attached to commit SHAs. Any operation that changes SHAs (rebase, amend, cherry-pick, etc.) will orphan the attestations. This makes the current implementation **unsuitable for real-world use** where rebasing is standard practice.

**What this demonstrates:** The value of transparent AI attribution and what it would take to implement it properly. Real support would require native integration in Git, GitHub, and other platforms.

See [Known Limitations](#known-limitations) for full details.

---

## The Problem

Open source maintainers face a flood of AI-generated pull requests with no way to understand context, intent, or effort. Was this thoughtful contribution or drive-by AI spam?

This toolkit provides **opt-in transparency** so honest contributors can easily show:
- What prompts they used
- Which files AI touched
- The iteration process (debugging, refinement)

**Why this matters:** See [`docs/WHAT-THIS-GETS-US.md`](docs/WHAT-THIS-GETS-US.md) for the full value proposition on git notes, signing layers, and trust model.

## How It Works

1. **Capture** - Claude Code hooks log file modifications and prompts automatically
2. **Sign** - Attestations are cryptographically signed with ed25519 toolkit key
3. **Attach** - Post-commit hook attaches signed attestation as git note
4. **Surface** - GitHub Action labels PRs and shows prompts and signature status to reviewers

*See it in action: [leeroy-demo repository](https://github.com/metcalfc/leeroy-demo)*

### Two-Layer Signing

Attestations include two levels of signatures for authenticity:

**Layer 1: Tool Signature** 🔐
- Toolkit signs each attestation with an ed25519 key (auto-generated on first use)
- Raises the bar for forgery - can't hand-craft attestations
- Verified with `leeroy verify <commit>`

**Layer 2: Contributor Signature** ✍️
- Standard git commit signing (GPG/SSH)
- Enable with: `git config commit.gpgsign true`
- Links your identity to AI-assisted work
- Shown in GitHub Action PR comments

Together, these provide accountability and authenticity.

## Known Limitations

This is a **proof of concept** demonstrating the core ideas. The following limitations are acceptable for a POC but would need to be addressed for production use:

### 1. Git Notes Lost on Rebase/Amend ⚠️ **CRITICAL**

**Issue**: Git notes are attached to commit SHAs. Any operation that changes the SHA orphans the attestation.

**Operations that break attestations:**
- `git commit --amend`
- `git rebase` (interactive or standard)
- `git cherry-pick`
- `git filter-branch` / `git filter-repo`
- Any history rewriting operation

**Impact**: **Makes this POC unsuitable for real-world use.** Modern Git workflows rely heavily on rebasing (interactive rebase to clean up commits, rebase to update feature branches, amend to fix commit messages/signatures, etc.).

**Example:**
```bash
# Create commit with attestation
git commit -m "Add feature"
leeroy show HEAD  # ✓ Attestation present

# Rebase or amend
git commit --amend --gpg-sign  # Adds signature, creates new SHA
leeroy show HEAD  # ✗ Attestation lost - attached to old SHA

# The old note is orphaned
git notes --ref=leeroy list  # Shows note for old SHA that's no longer in history
```

**Workarounds:**
```bash
# Manually copy notes after rebase/amend
OLD_SHA=abc1234  # SHA before rebase
NEW_SHA=def5678  # SHA after rebase
git notes --ref=leeroy copy $OLD_SHA $NEW_SHA

# Or use git's notes.rewriteRef config (limited support)
git config notes.rewriteRef refs/notes/leeroy
# This handles amend/rebase in some cases, but not reliably
```

**Why this can't be fixed in a POC:**

Git notes are fundamentally tied to SHAs. When a SHA changes, the note stays with the old SHA. While Git has some support for note rewriting (`notes.rewriteRef`), it's:
- Not reliable for all operations
- Not supported by GitHub/GitLab/etc.
- Doesn't work for force pushes or history that's already published

**What would fix this:**

Native platform support where attestations are:
- First-class metadata like commit signatures
- Preserved across history rewrites
- Synced automatically by Git/GitHub/GitLab
- Part of the commit object itself, or stored in a way that survives rebasing

This POC demonstrates the **value** of AI attestation and what the **format and workflows** could look like. The technical implementation requires platform-level support to be production-ready.

### 2. Session File Race Conditions

**Issue**: The session JSON file (`~/.leeroy/current-session.json`) can be corrupted if multiple processes modify it simultaneously.

**Impact**: Rare - only occurs if Claude makes rapid edits that trigger hooks at the exact same time.

**Status**: Acceptable for POC (single-user, typical workflows). Production would need file locking or atomic writes.

### 3. Unbounded Log Growth

**Issue**: The `~/.leeroy/prompts.log` file grows indefinitely with no rotation.

**Impact**: Disk usage increases over time. After months of use, could be several MB.

**Workaround**: Manually delete or archive the file periodically:
```bash
# Archive old prompts
mv ~/.leeroy/prompts.log ~/.leeroy/prompts.$(date +%Y%m%d).log

# Or simply clear it
rm ~/.leeroy/prompts.log
```

**Production fix**: Implement log rotation (logrotate or built-in size limits).

### 4. Prompts Cleared on Branch Switch

**Issue**: The flat `prompts.log` file is cleared when you switch branches.

**Impact**: Lose historical prompt context across branches.

**Rationale**: By design - prevents cross-branch contamination. Session data is tied to the branch you're on.

**Alternative**: Could implement per-branch logs or never clear historical logs (design decision).

### 5. No Format Versioning

**Issue**: Session files and attestation format have no version field or migration path.

**Impact**: Toolkit updates might change formats and break existing sessions.

**Workaround**: Clear active sessions before updating:
```bash
rm ~/.leeroy/current-session.json
```

**Production fix**: Add `Version: 1.0` field to session JSON and attestation format, implement migration logic.

### 6. Single Installation Path

**Issue**: Installation path is hardcoded to `~/.leeroy`.

**Impact**: Cannot have multiple configurations or per-project customization.

**Workaround**: None currently.

**Production fix**: Support `LEEROY_DIR` environment variable or per-repo config.

### 7. No Session Rollback

**Issue**: If attestation attachment fails, the session is still cleared (see `post-commit-attestation.sh:89`).

**Impact**: Session data is lost on failures.

**Mitigation**: Session prompts are also written to `prompts.log` as a backup.

**Production fix**: Two-phase commit - only clear session after successful note attachment.

### 8. Limited Concurrency Protection

**Issue**: Rapid commits or concurrent git operations could create race conditions.

**Impact**: Unlikely in normal single-user workflows.

**Production fix**: Proper locking, atomic operations, and retry logic.

### 9. Temp Ref Collision (Fixed)

**Issue**: ~~Git pre-push hook used a fixed temp ref name that could collide.~~

**Status**: ✅ **Fixed** - Now uses PID-based unique temp ref: `refs/notes/leeroy-push-compare-$$`

### What This POC Demonstrates

Despite these limitations, the POC successfully shows:
- ✅ Automatic prompt and file tracking works
- ✅ Cryptographic signing raises the bar for forgery
- ✅ Git notes provide clean separation from commits
- ✅ GitHub Actions can surface AI transparency to reviewers
- ✅ Two-layer signing (tool + contributor) provides accountability

These limitations are **documented trade-offs** for a proof of concept focused on demonstrating value, not production hardening.

## Installation

```bash
git clone https://github.com/your-org/leeroy
cd leeroy
./install.sh
```

Add to your shell profile:

```bash
export PATH="${PATH}:${HOME}/.leeroy/bin"
```

This installs:
- Hooks to `~/.leeroy/hooks/`
- Git hooks to `~/.leeroy/git-hooks/`
- CLI tools to `~/.leeroy/bin/`
- Claude Code hook configuration to `~/.claude/settings.json`

### Per-Repository Setup (Optional but Recommended)

Install git hooks in each repository where you want automatic attestation:

```bash
cd /path/to/your/repo
leeroy install-hooks
```

This enables attestation **regardless of commit method** (CLI, IDE, GUI). Without this, attestations only work when committing through Claude Code.

The git hooks provide:
- **prepare-commit-msg** - Shows AI summary before commit
- **post-commit** - Automatically attaches attestation
- **pre-push** - Auto-pushes attestation notes
- **post-checkout** - Clears sessions on branch switch

## Usage

### During Development

**Zero configuration required!** Claude Code automatically:
- Tracks files it modifies
- Captures your prompts when submitted

Just work with Claude normally. Everything is logged automatically.

**Optional manual logging** (for non-Claude work or additional context):
```bash
leeroy-log "researched OAuth flow before asking Claude"
leeroy-log "manually tweaked regex after Claude's suggestion"
```

### Committing

**With git hooks installed** (recommended):
Commit from anywhere - CLI, IDE, or GUI. The attestation is attached automatically:

```bash
git commit -m "Fix null check in parser"
# Output: ✓ Leeroy attestation attached to commit abc1234
```

**Without git hooks**:
Only works when committing through Claude Code (using the `/commit` command or commit function).

### Pushing Notes

Git notes are stored separately from commits.

**With git hooks installed**: Notes are automatically pushed when you `git push` (via pre-push hook).

**Without git hooks**: Push manually:
```bash
leeroy push
# Or manually:
git push origin refs/notes/leeroy
```

### Querying Attestations

```bash
# List Leeroy-attested commits
leeroy list

# Show attestation for a commit
leeroy show abc1234

# Repository statistics
leeroy stats

# Verify attestation format
leeroy verify HEAD
```

## Attestation Format

```
-----BEGIN AI ATTESTATION-----
Version: 1.0
Tool: claude-code/1.0.32
Model: claude-sonnet-4-20250514
Session-ID: a8f3k2x9
Started-At: 2025-01-16T14:20:00Z
Committed-At: 2025-01-16T14:25:00Z

Files-Modified:
  - src/parser.ts [modified] @ 2025-01-16T14:21:00Z
  - src/test/parser.test.ts [created] @ 2025-01-16T14:23:00Z

Prompts:
  [2025-01-16T14:20:01Z] fix the null check in parser.ts
  [2025-01-16T14:21:45Z] add a test for the edge case

Human-Review-Attested: true
-----END AI ATTESTATION-----
```

Stored as git notes under `refs/notes/leeroy`.

## GitHub Integration

Copy `.github/workflows/ai-transparency.yml` to your repo. PRs will be labeled:

- `ai-assisted` - All commits have Leeroy attestation
- `ai-assisted-partial` - Some commits have attestation
- `no-leeroy` - No attestation found

The workflow posts a comment showing:
- Models used
- Which commits have attestation
- Preview of prompts

Example:

```
## 🤖 AI Transparency Report

**2/3** commits in this PR have Leeroy attestation.

**Models used:** claude-sonnet-4-20250514

### AI-Assisted Commits
- `abc1234` Fix null check in parser
- `def5678` Add tests

### Commits Without Attestation
- `ghi9012` Update README

### Prompt Preview
**Commit abc1234:**
  [14:20:01] fix the null check in parser.ts
  [14:21:45] add a test for the edge case
```

## For Maintainers

### Fetching Notes

Before reviewing a PR, fetch the attestation notes:

```bash
git fetch origin refs/notes/leeroy:refs/notes/leeroy
```

### Viewing Attestations

```bash
# See attestations in log
git log --notes=leeroy

# Check specific commit
git notes --ref=leeroy show <commit>
```

### Policy Example

Add to your CONTRIBUTING.md:

```markdown
## AI-Assisted Contributions

We welcome AI-assisted contributions! To help us review effectively:

1. Install the [leeroy toolkit](...)
2. Log your prompts during AI sessions
3. Push attestation notes with your PR

This helps us understand the context of your changes.
```

## Value Proposition

See [`docs/WHAT-THIS-GETS-US.md`](docs/WHAT-THIS-GETS-US.md) for details on:
- Why git notes (portable, survives repo operations)
- Signing layers (tool signature, contributor signature, provider signature)
- Trust model (social norm + friction, not fraud detection)
- What maintainers can do with this data

## Testing

The toolkit includes a comprehensive test suite with 55 tests covering unit, integration, and end-to-end scenarios.

### Prerequisites

Install bats (Bash Automated Testing System):

```bash
# Arch Linux
sudo pacman -S bats

# Ubuntu/Debian
sudo apt-get install bats

# macOS
brew install bats-core
```

### Running Tests

```bash
# Run all tests
./run-tests.sh

# Run specific test file
./run-tests.sh -f tests/session-tracker.bats
./run-tests.sh -f tests/signing.bats
./run-tests.sh -f tests/integration.bats

# Run with verbose output
./run-tests.sh -v
```

### Test Coverage

**Unit Tests:**
- `tests/session-tracker.bats` (20 tests) - Session initialization, file logging, prompt logging, session management
- `tests/signing.bats` (25 tests) - Key generation, signing, verification, tampering detection

**Integration Tests:**
- `tests/integration.bats` (10 tests) - Full workflow, CLI tools, multiple sessions, signature verification

**What's Tested:**
- ✅ Session tracking and initialization
- ✅ File modification logging
- ✅ Automatic prompt capture
- ✅ Ed25519 key generation
- ✅ Attestation signing and verification
- ✅ Tampering detection
- ✅ Full commit workflow
- ✅ CLI tools (list, show, verify, stats)
- ✅ Environment variable handling
- ✅ Error conditions and edge cases

All tests pass on Linux. See `IMPLEMENTATION_PLAN.md` for test implementation details.

## Contributing

PRs welcome. Please use the leeroy toolkit when contributing.

For development guidance, see [`CLAUDE.md`](CLAUDE.md).

## License

MIT
