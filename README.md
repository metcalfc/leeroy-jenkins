# Leeroy

**At least you'll have attestation.**

Transparent attribution for AI-assisted code contributions.

![Leeroy Demo](demo.gif)

[Watch the original Leeroy Jenkins](https://www.youtube.com/watch?v=mLyOj_QD4a4)

---

## Two Versions

### [Today](today/) - Use it now

Embeds AI attestation directly into commit messages. Works with any git host, any workflow, no ecosystem changes required.

```bash
cd today && ./install.sh
```

```
$ git commit -m "Add feature"

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

```bash
cd tomorrow && ./install.sh
```

```
$ git commit -m "Add feature"

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

## Quick Start

**Choose one:**

```bash
# Today - embed in commit messages (recommended)
cd today && ./install.sh

# Tomorrow - use git notes (experimental)
cd tomorrow && ./install.sh
```

Then:

```bash
export PATH="${PATH}:${HOME}/.leeroy/bin"

cd /path/to/your/repo
leeroy install-hooks
```

Work with Claude Code normally. Attestations are attached automatically when you commit.

## Comparison

| Feature | Today | Tomorrow |
|---------|-------|----------|
| Works now | Yes | Requires ecosystem changes |
| Travels with commits | Yes | No (separate push) |
| Full prompt text | Yes | Yes |
| Tool signatures | No | Yes |
| Survives rebase | Yes (part of message) | No |
| Commit message size | Larger | Unchanged |

## CLI Commands

Both versions use the same CLI:

```bash
leeroy list           # List AI-assisted commits
leeroy show HEAD      # Show attestation for a commit
leeroy stats          # Show repo statistics
leeroy install-hooks  # Install git hooks in current repo
```

Tomorrow version adds:
```bash
leeroy verify HEAD    # Verify tool signature
leeroy fetch          # Fetch notes from origin
leeroy push           # Push notes to origin
```

## For Maintainers

Add to your CONTRIBUTING.md:

```markdown
## AI-Assisted Contributions

We welcome AI-assisted contributions! To help us review effectively:

1. Install the [Leeroy toolkit](https://github.com/metcalfc/leeroy-jenkins)
2. Commit normally - attestations are automatic
3. Your prompts and AI tool info will be visible in commits
```

## Requirements

- `jq` - JSON processing
- `openssl` - Session ID generation
- `git`

## See Also

- [docs/WHAT-THIS-GETS-US.md](docs/WHAT-THIS-GETS-US.md) - Value proposition and trust model
- [today/README.md](today/README.md) - Today version details
- [tomorrow/README.md](tomorrow/README.md) - Tomorrow version details

## License

MIT
