# GitHub Actions

Leeroy includes GitHub Actions for validating and labeling pull requests based on attestation.

## PR Gatekeeper

Validates PRs based on contributor trust OR attestation.

### How It Works

1. **Check author permissions** - Does the PR author have write access?
2. **Check attestation** - Do commits have AI or human attestation?
3. **Decision:**
   - ✅ Approved if author has write access (trusted contributor)
   - ✅ Approved if any commits have attestation
   - ❌ Rejected if no write access AND no attestation

### Setup

Copy `today/github-action/pr-gatekeeper.yml` to your repository's `.github/workflows/` directory:

```bash
mkdir -p .github/workflows
cp today/github-action/pr-gatekeeper.yml .github/workflows/
```

### Labels Applied

| Label | Meaning |
|-------|---------|
| `trusted-contributor` | Author has write access to repo |
| `ai-assisted` | All commits have AI attestation |
| `human-attested` | All commits have human attestation |
| `attested-mixed` | Mix of AI and human attestation |
| `attested-partial` | Some commits have attestation |
| `no-attestation` | No attestation (PR rejected) |

### PR Comment

The action posts a comment with details:

```markdown
## ✅ PR Gatekeeper: PR Approved

### Contributor Status
- **Author:** @contributor
- **Permission Level:** read
- **Write Access:** ❌ No

### Attestation Status
- **Total attested commits:** 3/3
  - 🤖 AI-assisted: 2
  - 👤 Human-attested: 1

### Decision
✅ **Approved:** All commits are attested (2 AI-assisted, 1 human-authored).
```

### Customization

Edit the workflow to change behavior:

```yaml
# Require ALL commits to have attestation (not just some)
elif [[ "${all_attested}" == "true" ]]; then
  echo "status=approved" >> $GITHUB_OUTPUT
elif [[ "${has_attestation}" == "true" ]]; then
  echo "status=rejected" >> $GITHUB_OUTPUT  # Change from approved
```

---

## Transparency Check (Tomorrow Version)

For the git notes version, copy `tomorrow/github-action/ai-transparency.yml` to your repository's `.github/workflows/` directory:

```bash
mkdir -p .github/workflows
cp tomorrow/github-action/ai-transparency.yml .github/workflows/
```

### Additional Setup

Notes must be pushed to the remote:

```bash
git push origin refs/notes/leeroy
```

The workflow fetches notes and analyzes them:

```yaml
- name: Fetch Leeroy attestation notes
  run: |
    git fetch origin refs/notes/leeroy:refs/notes/leeroy 2>/dev/null || true
```

### Labels

| Label | Meaning |
|-------|---------|
| `ai-assisted` | All commits have attestation notes |
| `ai-assisted-partial` | Some commits have attestation |
| `no-leeroy` | No attestation notes found |

---

## Required Permissions

Both workflows need:

```yaml
permissions:
  contents: read
  pull-requests: write
```

The `pull-requests: write` permission is needed to:
- Add/remove labels
- Post comments

---

## Troubleshooting

### Labels not appearing

Ensure the labels exist in your repository. GitHub Actions can create labels automatically, but you may need to create them manually first with colors:

- `trusted-contributor` - Green (#0e8a16)
- `ai-assisted` - Blue (#1d76db)
- `human-attested` - Purple (#5319e7)
- `attested-mixed` - Teal (#0052cc)
- `attested-partial` - Yellow (#fbca04)
- `no-attestation` - Red (#d93f0b)

### Permissions errors

If you see "Resource not accessible by integration":
1. Check the workflow has correct permissions
2. For forks, the action may have limited permissions

### Notes not found (tomorrow version)

Ensure notes are pushed before opening the PR:

```bash
git push origin refs/notes/leeroy
```
