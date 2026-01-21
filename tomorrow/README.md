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
leeroy verify HEAD  # Verify tool signature
leeroy fetch        # Fetch notes from origin
leeroy push         # Push notes to origin
```

## Documentation

- [Installation Guide](../docs/installation.md)
- [CLI Reference](../docs/cli-reference.md)
- [GitHub Actions](../docs/github-actions.md)

## Files

```
~/.leeroy/
├── hooks/
│   ├── session-tracker.sh
│   ├── capture-prompt.sh
│   ├── post-tool-use-wrapper.sh
│   ├── post-commit-attestation.sh
│   └── sign-attestation.sh
├── git-hooks/
│   ├── prepare-commit-msg
│   ├── post-commit
│   ├── pre-push
│   └── post-checkout
├── bin/
│   └── leeroy
└── toolkit.key  # ed25519 signing key
```
