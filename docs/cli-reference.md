# CLI Reference

## Commands

### leeroy install-hooks

Install git hooks in the current repository.

```bash
cd /path/to/repo
leeroy install-hooks
```

Installs:
- `prepare-commit-msg` - Embeds attestation in commit messages
- `post-commit` - Clears session after commit
- `post-checkout` - Clears session on branch switch

Existing hooks are backed up with `.backup` extension.

---

### leeroy list [n]

List recent commits with attestation.

```bash
leeroy list      # Last 10 commits
leeroy list 20   # Last 20 commits
```

Output:
```
Recent AI-assisted commits:

abc1234 Add feature X
def5678 Fix bug in parser
```

---

### leeroy show [ref]

Show attestation for a specific commit.

```bash
leeroy show          # HEAD
leeroy show abc1234  # Specific commit
leeroy show HEAD~1   # Previous commit
```

Output:
```
AI Attestation for abc1234:

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
```

Also shows human attestation:
```
Human Attestation for def5678:

---
AI-Assisted: false
Human-Attested: true
Attested-By: Jane Doe <jane@example.com>
Attested-At: 2024-01-15T11:00:00Z
```

---

### leeroy stats

Show attestation statistics for the repository.

```bash
leeroy stats
```

Output:
```
Attestation Stats for my-project

Total commits:    150
AI-assisted:      45
Human-attested:   20
Total attested:   65 (43%)
```

---

### leeroy attest-human

Attest that the HEAD commit was human-authored (no AI assistance).

```bash
git commit -m "Fix typo in README"
leeroy attest-human
```

Output:
```
Human attestation added to abc1234

Attestation:
  AI-Assisted: false
  Human-Attested: true
  Attested-By: Jane Doe <jane@example.com>
  Attested-At: 2024-01-15T11:00:00Z
```

This amends the commit to add the attestation block. Can only be run on HEAD.

---

### leeroy help

Show help message.

```bash
leeroy help
```

---

## Tomorrow Version Additional Commands

These commands are only available in the tomorrow (git notes) version:

### leeroy verify [ref]

Verify the tool signature on an attestation.

```bash
leeroy verify HEAD
```

### leeroy fetch

Fetch attestation notes from origin.

```bash
leeroy fetch
```

Equivalent to:
```bash
git fetch origin refs/notes/leeroy:refs/notes/leeroy
```

### leeroy push

Push attestation notes to origin.

```bash
leeroy push
```

Equivalent to:
```bash
git push origin refs/notes/leeroy
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (not in git repo, invalid ref, etc.) |

## Environment

The CLI uses these paths:
- `~/.leeroy/` - Installation directory
- `~/.leeroy/hooks/session-tracker.sh` - Session tracking
- Git config `user.name` and `user.email` for human attestation
