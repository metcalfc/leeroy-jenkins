# Leeroy - Tomorrow Version

**The full vision. Requires git/GitHub ecosystem changes.**

Uses git notes for rich attestation data with cryptographic signatures.

## What is this?

The "proper" way to do AI attestation - using git notes to store detailed attestation data separate from commit messages. This allows for:

- Full prompt text capture
- Per-file modification timestamps
- Cryptographic tool signatures
- Rich structured data

**However**, it requires:
- Explicitly pushing/fetching notes refs
- GitHub/GitLab to display notes in their UI
- CI systems to fetch notes refs
- Developers to understand git notes

## Installation

```bash
cd tomorrow
./install.sh

# Add to your PATH
export PATH="${PATH}:${HOME}/.leeroy/bin"

# Install git hooks in your repo
cd /path/to/your/repo
leeroy install-hooks
```

## How it works

```
# Make changes with Claude Code...
$ git commit -m "Add feature"

# Attestation is attached as a git note
$ git notes --ref=leeroy show HEAD
-----BEGIN AI ATTESTATION-----
Version: 1.0
Tool: claude-code/1.0.0
Model: claude-sonnet-4-20250514
Session-ID: abc12345
Started-At: 2024-01-15T10:30:00Z
Committed-At: 2024-01-15T11:45:00Z

Files-Modified:
  - src/feature.py [modified] @ 2024-01-15T10:35:00Z

Prompts:
  [2024-01-15T10:30:00Z] Add a feature that does X
  [2024-01-15T10:40:00Z] Fix the error handling

Human-Review-Attested: true

Tool-Signature: ed25519:base64signature...
Tool-Key-Fingerprint: sha256:fingerprint...
-----END AI ATTESTATION-----

# Must push notes separately
$ git push origin refs/notes/leeroy
```

## Attestation format

Full PGP-style format with:
- Version header
- Tool and model identification
- Session tracking
- Per-file timestamps
- Full prompt text
- Cryptographic signature

## CLI commands

```bash
leeroy list           # List commits with attestations
leeroy show HEAD      # Show attestation for a commit
leeroy stats          # Show repo statistics
leeroy verify HEAD    # Verify attestation signature
leeroy fetch          # Fetch attestation notes from origin
leeroy push           # Push attestation notes to origin
leeroy install-hooks  # Install git hooks in current repo
```

## Trade-offs vs Today version

| Feature | Tomorrow (git notes) | Today (commit msg) |
|---------|---------------------|-------------------|
| Full prompt text | Yes | No (count only) |
| Tool signatures | Yes | No |
| Per-file timestamps | Yes | No |
| Works now | Requires ecosystem changes | Yes |
| Portability | Requires separate push/fetch | Travels with commits |
| Complexity | More complex | Simple |

## What needs to change for this to work well

1. **GitHub/GitLab UI**: Display git notes in commit views
2. **CI systems**: Auto-fetch notes refs
3. **Git clients**: Better notes support
4. **Default behavior**: Notes should push/fetch by default

Until then, use the **Today** version for practical AI attestation.

## Requirements

- `jq` - JSON processing
- `openssl` - Session ID generation and ed25519 signing
- `git` 1.6.6+ (notes support)

## Files

```
~/.leeroy/
  hooks/
    session-tracker.sh        # Track AI session
    capture-prompt.sh         # Auto-capture prompts
    post-tool-use-wrapper.sh  # Track file modifications
    post-commit-attestation.sh # Format and attach note
    sign-attestation.sh       # ed25519 signing
  git-hooks/
    git-prepare-commit-msg    # Show AI summary
    git-post-commit           # Attach attestation
    git-pre-push              # Auto-push notes
    git-post-checkout         # Clear sessions
  bin/
    leeroy                    # CLI tool
  toolkit.key                 # ed25519 private key (generated)
```
