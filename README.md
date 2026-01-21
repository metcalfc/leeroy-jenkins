# Leeroy

**At least you'll have attestation.**

Transparent attribution for AI-assisted code contributions.

## Quick Start

```bash
git clone https://github.com/metcalfc/leeroy-jenkins.git
cd today && ./install.sh
export PATH="${PATH}:${HOME}/.leeroy/bin"

cd /path/to/your/repo
leeroy install-hooks
```

Work with Claude Code normally. Attestations are attached automatically when you commit.

## Two Versions

### [Today](today/) - Use it now

Embeds AI attestation directly into commit messages. Works with any git host, any workflow, no ecosystem changes required.

![Leeroy Demo](demo-commits.gif)

```
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

**Pros:** Works today, travels with commits, full prompt text
**Cons:** Commit messages are larger

### [Tomorrow](tomorrow/) - The full vision

Uses git notes for rich attestation with cryptographic signatures and full prompt text. Demonstrates what's possible with platform support.

![Leeroy Demo](demo-notes.gif)

```
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
```

**Pros:** Full prompt text, tool signatures, rich metadata
**Cons:** Requires `git push origin refs/notes/leeroy`, notes lost on rebase

---

## The Problem

Open source maintainers face a flood of AI-generated pull requests with no way to understand context, intent, or effort. Was this thoughtful contribution or drive-by AI spam?

This toolkit provides **opt-in transparency** so honest contributors can show:
- What prompts they used
- Which files AI touched
- The iteration process

## Comparison

| Feature | Today | Tomorrow |
|---------|-------|----------|
| Works now | Yes | Requires ecosystem changes |
| Travels with commits | Yes | No (separate push) |
| Full prompt text | Yes | Yes |
| Tool signatures | No | Yes |
| Survives rebase | Yes (part of message) | No |
| Commit message size | Larger | Unchanged |

## Documentation

- **[Installation](docs/installation.md)** - Detailed setup for both versions
- **[CLI Reference](docs/cli-reference.md)** - All commands and options
- **[GitHub Actions](docs/github-actions.md)** - PR validation and labeling
- **[For Maintainers](docs/for-maintainers.md)** - Adding Leeroy to your project
- **[Why Leeroy?](docs/WHAT-THIS-GETS-US.md)** - Value proposition and trust model

## Requirements

- `jq` - JSON processing
- `openssl` - Session ID generation
- `git`

## License

MIT

---

[Lets reminisce about the good ol' days and watch the original Leeroy Jenkins](https://www.youtube.com/watch?v=mLyOj_QD4a4)
