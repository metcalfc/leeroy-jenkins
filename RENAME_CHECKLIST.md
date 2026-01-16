# Leeroy Rename Checklist

Comprehensive checklist for renaming "ai-attestation" to "leeroy"

## Global Find/Replace Strategy

**Primary replacements:**
- `ai-attestation` → `leeroy`
- `AI Attestation` → `Leeroy`
- `AI_ATTESTATION` → `LEEROY`
- `refs/notes/ai-attestation` → `refs/notes/leeroy`

**CLI tool names:**
- `ai-attestation` → `leeroy`
- `ai-log-prompt` → `leeroy-log`
- `ai-session` → `leeroy-session`

**Paths:**
- `~/.ai-attestation/` → `~/.leeroy/`
- `${HOME}/.ai-attestation` → `${HOME}/.leeroy`
- `$HOME/.ai-attestation` → `$HOME/.leeroy`

---

## File-by-File Changes

### ✅ Core Scripts

#### [ ] install.sh
- [ ] Line 9: `INSTALL_DIR="${HOME}/.ai-attestation"` → `"${HOME}/.leeroy"`
- [ ] Line 10: `CLAUDE_SETTINGS="${HOME}/.claude/settings.json"` (keep as-is)
- [ ] Line 12: Header comment: "AI Attestation Installation" → "Leeroy Installation"
- [ ] Line 44: "Installing AI Attestation Toolkit" → "Installing Leeroy Toolkit"
- [ ] Line 32: Symlink `ai-log-prompt` → `leeroy-log`
- [ ] Line 33: Symlink `ai-session` → `leeroy-session`
- [ ] Line 36: CLI script name: `ai-attestation` → `leeroy`
- [ ] Line 38-39: Header comment in embedded CLI
- [ ] Line 44: `ATTESTATION_REF="refs/notes/ai-attestation"` → `"refs/notes/leeroy"`
- [ ] Lines 46-265: All function references to git notes ref
- [ ] Line 228: Help text "AI Attestation CLI" → "Leeroy CLI"
- [ ] Line 233: Usage examples
- [ ] Line 268: Success message
- [ ] Lines 279-325: Hook configuration paths
- [ ] Line 337-361: Installation instructions

#### [ ] hooks/session-tracker.sh
- [ ] Line 3: Header comment
- [ ] Line 15: `ATTESTATION_DIR="${HOME}/.ai-attestation"` → `"${HOME}/.leeroy"`
- [ ] Line 16-17: Derived paths (SESSION_FILE, PROMPT_LOG)

#### [ ] hooks/post-commit-attestation.sh
- [ ] Line 3: Header comment
- [ ] Line 14: `ATTESTATION_REF="refs/notes/ai-attestation"` → `"refs/notes/leeroy"`
- [ ] Line 21-22: Log messages
- [ ] Line 78: Success message with commit message

#### [ ] hooks/sign-attestation.sh
- [ ] Line 4: Header comment
- [ ] Line 6: `AI_DIR="${HOME}/.ai-attestation"` → `LEEROY_DIR="${HOME}/.leeroy"`
- [ ] Line 7-9: Update variable references to LEEROY_DIR
- [ ] Line 57-58: Temp file prefix `ai-attestation-sign` → `leeroy-sign`
- [ ] Line 100-101: Temp file prefix `ai-attestation-verify-*` → `leeroy-verify-*`

#### [ ] hooks/log-prompt.sh
- [ ] Header comment
- [ ] Line 8: Script directory path resolution
- [ ] Line 15: Usage message

#### [ ] hooks/capture-prompt.sh
- [ ] Line 2: Header comment
- [ ] Line 15: Debug log path comment (if uncommented)

---

### ✅ Git Hooks

#### [ ] hooks/git-prepare-commit-msg
- [ ] Line 15: `SESSION_FILE="${HOME}/.ai-attestation/current-session.json"` → `"${HOME}/.leeroy/..."`
- [ ] Line 45-51: AI summary comment block

#### [ ] hooks/git-post-commit
- [ ] Line 13: `ATTESTATION_SCRIPT="${HOME}/.ai-attestation/hooks/..."` → `"${HOME}/.leeroy/..."`

#### [ ] hooks/git-pre-push
- [ ] Line 14-15: Comments about AI attestation notes
- [ ] Line 25: `TEMP_REF="refs/notes/ai-attestation-push-compare-$$"` → `"refs/notes/leeroy-push-compare-$$"`
- [ ] Line 27: Git ls-remote check for `refs/notes/ai-attestation` → `refs/notes/leeroy`
- [ ] Line 29: Git fetch ref
- [ ] Line 31-41: All references to attestation ref
- [ ] Line 42: Log message "Pushing AI attestation notes" → "Pushing Leeroy attestation notes"

#### [ ] hooks/git-post-checkout
- [ ] Line 16: `SESSION_FILE="${HOME}/.ai-attestation/current-session.json"` → `"${HOME}/.leeroy/..."`
- [ ] Line 56: `PROMPTS_LOG="${HOME}/.ai-attestation/prompts.log"` → `"${HOME}/.leeroy/..."`

---

### ✅ Test Files

#### [ ] tests/session-tracker.bats
- [ ] Line 6: Test description header
- [ ] Line 13: `TEST_DIR="${HOME}/.ai-attestation-test-$$"` → `"${HOME}/.leeroy-test-$$"`
- [ ] Line 14-16: Test file paths
- [ ] All test descriptions mentioning "ai-attestation"

#### [ ] tests/signing.bats
- [ ] Line 6: Test description header
- [ ] Line 13: `TEST_DIR="${HOME}/.ai-attestation-test-$$"` → `"${HOME}/.leeroy-test-$$"`
- [ ] Line 14-17: Test paths
- [ ] Line 20-28: Sample attestation BEGIN/END markers (keep as "AI ATTESTATION" for format compatibility)
- [ ] Test descriptions

#### [ ] tests/integration.bats
- [ ] Line 6: Test description header
- [ ] Line 13-14: Setup paths
- [ ] Line 19: Git notes ref `refs/notes/ai-attestation` → `refs/notes/leeroy`
- [ ] Line 23-45: Test setup copying hooks
- [ ] All test descriptions

#### [ ] run-tests.sh
- [ ] Line 4: Header comment
- [ ] Line 14: Echo message
- [ ] Line 50-54: Help text
- [ ] Line 87: Temp file prefix in shellcheck section

#### [ ] test-prompt-capture.sh
- [ ] Line 4: Header comment
- [ ] Test data and messages

---

### ✅ Documentation

#### [ ] README.md
- [ ] Line 1: Title "# AI Attestation Toolkit" → "# Leeroy"
- [ ] Line 3: Subtitle
- [ ] Add paragraph about the name (use the one from conversation)
- [ ] Line 12-14: Update references to toolkit name
- [ ] Line 40-52: Installation instructions with new paths
- [ ] Line 54-76: Per-repository setup with new CLI name
- [ ] Line 77-92: Usage section with new CLI commands
- [ ] Line 93-130: All command examples
- [ ] Line 131-180: CLI reference with new command names
- [ ] Known Limitations section: update paths
- [ ] All code blocks with commands

#### [ ] CLAUDE.md
- [ ] Line 3: Project overview header
- [ ] Line 5: Core value statement
- [ ] Line 11: Architecture section paths
- [ ] Line 12-14: Session tracking paths
- [ ] Line 31: Attestation storage description
- [ ] Line 38-50: Attestation format (keep "AI ATTESTATION" markers for compatibility)
- [ ] Line 88-97: Development commands
- [ ] Line 100-108: Testing section
- [ ] Line 111-150: Key files section
- [ ] Line 153-180: Implementation details
- [ ] Line 191-202: Claude Code hook config
- [ ] Line 207-209: Dependencies section
- [ ] All file path references

#### [ ] IMPLEMENTATION_PLAN.md
- [ ] Title and headers
- [ ] All references to toolkit name
- [ ] File paths in implementation notes
- [ ] Code examples

#### [ ] docs/WHAT-THIS-GETS-US.md
- [ ] Check for any references to toolkit name or paths
- [ ] Keep attestation format examples as-is (backward compatibility)

---

### ✅ CI/CD and Config

#### [ ] .github/workflows/ai-transparency.yml
- [ ] Line 1: Workflow name
- [ ] Line 24: Git fetch notes ref `refs/notes/ai-attestation` → `refs/notes/leeroy`
- [ ] Line 52: Git notes show command
- [ ] Line 154: Remove label mentions
- [ ] Line 216: Link to toolkit (update when published)
- [ ] Comments throughout

#### [ ] config/claude-code-hooks.json
- [ ] Line 2: Comment header
- [ ] Line 5: UserPromptSubmit command path `$HOME/.ai-attestation/` → `$HOME/.leeroy/`
- [ ] Line 9: PostToolUse command path
- [ ] Line 13: PostCommit command path

---

### ✅ Other Files

#### [ ] .gitignore
- [ ] Line 1-2: Update comment (keep as-is or update to reference Leeroy user installation)

#### [ ] .shellcheckrc
- [ ] Line 1: Update comment "AI Attestation Toolkit" → "Leeroy Toolkit"

---

## Branding Updates

### [ ] Add Leeroy Personality

#### Messages to update with 🐔 emoji:
- [ ] install.sh: Installation success message
- [ ] post-commit-attestation.sh: Attestation attached message
- [ ] git-pre-push: Pushing notes message
- [ ] CLI help text: Add tagline "At least you have attestation"
- [ ] README: Add personality to examples

#### Example messages:
```bash
# Before
✓ AI attestation attached to commit abc1234

# After
🐔 Leeroy attestation attached to commit abc1234
   At least you have attestation.
```

---

## Attestation Format Compatibility

**IMPORTANT:** Keep attestation format markers as-is for backward compatibility:
- `-----BEGIN AI ATTESTATION-----`
- `-----END AI ATTESTATION-----`
- Field names like `Human-Review-Attested: true`

These are part of the attestation format spec and changing them would break existing attestations.

---

## Testing Checklist

After completing all changes:

- [ ] Run shellcheck on all scripts: `./run-tests.sh` (shellcheck phase)
- [ ] Run session-tracker tests: `bats tests/session-tracker.bats`
- [ ] Run signing tests: `bats tests/signing.bats`
- [ ] Run integration tests: `bats tests/integration.bats`
- [ ] Test installation: `./install.sh` in a clean environment
- [ ] Test CLI commands:
  - [ ] `leeroy list`
  - [ ] `leeroy show HEAD`
  - [ ] `leeroy stats`
  - [ ] `leeroy verify HEAD`
  - [ ] `leeroy install-hooks`
- [ ] Test manual prompt logging: `leeroy-log "test prompt"`
- [ ] Test full workflow: edit → commit → verify attestation
- [ ] Verify git notes ref: `git notes --ref=leeroy list`
- [ ] Check installation directory: `ls -la ~/.leeroy/`

---

## Migration Notes for Existing Users

Users who have the old `ai-attestation` installed will need to:

1. Backup existing data:
   ```bash
   cp -r ~/.ai-attestation ~/.ai-attestation.backup
   ```

2. Run new installer (will create ~/.leeroy/)

3. Optional: Migrate git notes in existing repos:
   ```bash
   git notes --ref=leeroy copy refs/notes/ai-attestation
   ```

4. Update PATH in shell profile:
   ```bash
   # Old
   export PATH="${PATH}:${HOME}/.ai-attestation/bin"

   # New
   export PATH="${PATH}:${HOME}/.leeroy/bin"
   ```

---

## Search Patterns for Verification

After completing rename, search for these patterns to catch any missed references:

```bash
# Case-insensitive search for old name
grep -ri "ai.attestation" .
grep -ri "ai_attestation" .

# Check for old paths
grep -r "\.ai-attestation" .

# Check for old git notes ref
grep -r "refs/notes/ai-attestation" .

# Check for old CLI names
grep -r "ai-log-prompt" .
grep -r "ai-session" .
```

Exclude:
- `.git/` directory
- `RENAME_CHECKLIST.md` (this file)
- Git commit history
