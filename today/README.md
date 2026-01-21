# Leeroy - Today Version

**Use it today. No waiting for git/GitHub changes.**

AI attestation embedded directly into commit messages. Works with any git host, any workflow.

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

# Attestation is automatically added
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

For human-authored commits:

```bash
git commit -m "Fix typo"
leeroy attest-human
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
│   └── post-tool-use-wrapper.sh
├── git-hooks/
│   ├── prepare-commit-msg
│   ├── post-commit
│   └── post-checkout
└── bin/
    └── leeroy
```
