# For Maintainers

How to add Leeroy attestation requirements to your project.

## Adding to CONTRIBUTING.md

```markdown
## AI-Assisted Contributions

We welcome AI-assisted contributions! To help us review effectively:

1. Install the [Leeroy toolkit](https://github.com/metcalfc/leeroy-jenkins)
2. Commit normally - attestations are automatic for AI-assisted work
3. For human-authored commits, run `leeroy attest-human` after committing
4. Your prompts and AI tool info will be visible in commits

This helps maintainers understand the context and intent behind contributions.
```

## Policy Options

### Option 1: Transparency Appreciated

> "We appreciate attestation but don't require it"

- Add the GitHub Action for labeling
- Use labels to give reviewers context
- No enforcement

**Good for:** Projects wanting to encourage transparency without friction.

### Option 2: Required for External Contributors

> "First-time contributors must have attestation"

- Trusted contributors (write access) can commit freely
- External contributors need attestation
- Use PR Gatekeeper action to enforce

**Good for:** Projects concerned about drive-by AI spam.

### Option 3: Required for All

> "All commits must have attestation"

- Modify PR Gatekeeper to require all commits attested
- Applies to everyone, including maintainers

**Good for:** Projects wanting complete transparency records.

## Setting Up Enforcement

### 1. Add the GitHub Action

Copy `.github/workflows/pr-gatekeeper.yml` to your repository.

### 2. Create Labels

Create these labels in your repository:

| Label | Color | Description |
|-------|-------|-------------|
| `trusted-contributor` | `#0e8a16` | Author has write access |
| `ai-assisted` | `#1d76db` | AI-assisted commits |
| `human-attested` | `#5319e7` | Human-attested commits |
| `attested-mixed` | `#0052cc` | Mix of AI and human |
| `attested-partial` | `#fbca04` | Some commits attested |
| `no-attestation` | `#d93f0b` | No attestation found |

### 3. Make Check Required (Optional)

In repository settings:
1. Go to Settings → Branches → Branch protection rules
2. Add rule for `main` (or your default branch)
3. Enable "Require status checks to pass"
4. Add "validate-pr" as a required check

## Reading Attestations in Review

### AI-Assisted Commits

Look for scope match between prompts and changes:

```
AI-Prompts:
- [10:30:00] Fix the null check in parser.ts
- [10:35:00] Add a test for the edge case
```

✅ Good: Prompts match the PR scope
⚠️ Concern: Vague prompts like "rewrite the auth system"
⚠️ Concern: Single prompt for massive changes

### Human-Attested Commits

```
AI-Assisted: false
Human-Attested: true
Attested-By: Jane Doe <jane@example.com>
```

The contributor explicitly claims no AI was used.

### Mixed PRs

Some commits AI-assisted, some human-authored. This is normal for:
- Config file tweaks (human)
- Feature implementation (AI)
- Final polish (human)

## Handling Disputes

If someone claims a commit is incorrectly attested:

1. **Attestation is self-reported** - It reflects what the contributor claims
2. **No cryptographic proof** - Tool signatures prove toolkit was used, not content accuracy
3. **Focus on the code** - Review the actual changes, not the attestation

Attestation helps with context, but code review is still essential.

## Statistics

Track AI usage in your project:

```bash
leeroy stats
```

```
Attestation Stats for my-project

Total commits:    500
AI-assisted:      150
Human-attested:   100
Total attested:   250 (50%)
```

## FAQ

### What if someone doesn't want to share their prompts?

That's their choice. Projects can decide whether to require attestation or just appreciate it.

### Can attestation be faked?

Yes. This is about reducing friction for honest contributors, not preventing fraud. See [WHAT-THIS-GETS-US.md](WHAT-THIS-GETS-US.md) for the trust model.

### Should I reject PRs without attestation?

Depends on your policy. The PR Gatekeeper by default:
- Approves trusted contributors (write access) without attestation
- Approves external contributors WITH attestation
- Rejects external contributors WITHOUT attestation

### What about rebases?

Today version: Attestation survives (it's in the commit message)
Tomorrow version: Attestation is lost (notes don't follow rebased commits)
