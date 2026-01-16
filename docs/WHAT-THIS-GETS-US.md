# What AI Attestation Gets Us

## The Core Problem

Open source maintainers face a flood of AI-generated pull requests with no way to distinguish thoughtful contributions from drive-by AI spam. The commit itself is opaque:

```
commit abc1234
Author: developer@example.com
Date: 2025-01-16

    Fix null check in parser
```

Questions the maintainer has:
- Did they understand the codebase?
- Did they test this?
- Was this a mass AI PR spray?
- Will they respond to feedback?
- What was the actual intent?

No answers. Just vibes.

---

## Git Notes: Metadata That Travels With History

With attestation attached, the same commit tells a story:

```
commit abc1234
Author: developer@example.com
Date: 2025-01-16

    Fix null check in parser

[ai-attestation]
Model: claude-sonnet-4-20250514
Prompts:
  [14:20] fix the null check in parser.ts
  [14:22] also handle empty array case
  [14:25] add a test
```

Now the maintainer knows:
- ✓ AI was used (transparent)
- ✓ Scope of ask matches scope of change
- ✓ Human iterated on solution (3 prompts)
- ✓ Testing was considered

### Why Git Notes Specifically

| Property | Benefit |
|----------|---------|
| Attached to commits | Survives rebases, cherry-picks, merges |
| Part of git itself | No GitHub/GitLab dependency |
| Independent push/fetch | Can be managed separately from code |
| Standard git queries | `git log --notes=ai-attestation` just works |
| Non-polluting | Doesn't clutter commit messages |

Notes are the right primitive because they're portable. If you move repos, change hosts, or fork—the attestation follows the commits.

---

## Signing: Layers of Trust

Signing creates accountability, but with important caveats about what each layer actually proves.

### Layer 1: Tool Signature (Weak but Useful)

**What it says:** "This attestation was created by ai-attestation toolkit v1.0"

**Value:** Proves the contributor used the standard toolkit, not a hand-crafted fake.

**Weakness:** The signing key lives on the user's machine. It can be extracted and used to forge attestations.

**Realistic expectation:** Raises the bar for casual forgery. Someone has to actively extract the key and understand the schema to fake it.

### Layer 2: Contributor Signature (Strong for Identity)

**What it says:** "developer@example.com attests this is accurate"

**Value:** Ties the attestation to a verified identity (GPG/SSH key). You know *who* is making the claim.

**Weakness:** They could still lie about the content. The signature proves identity, not truthfulness.

**Realistic expectation:** Creates accountability. If attestations are later shown to be false, there's a verified identity attached.

### Layer 3: Provider Signature (Strong, Doesn't Exist Yet)

**What it says:** "Anthropic confirms this output was generated at this time"

**Value:** Unforgeable proof that AI was actually used and produced specific output.

**Weakness:** Doesn't exist. Would require Anthropic, OpenAI, etc. to issue signed receipts with API responses.

**Realistic expectation:** This is the end goal. This toolkit establishes the convention; provider signatures would make it trustworthy.

### Trust Matrix

| Feature | What It Proves | Trust Level | Forgeable? |
|---------|---------------|-------------|------------|
| Prompts in notes | Intent behind changes | Self-reported | Yes, but why bother? |
| Timestamps | When work happened | Local clock | Yes |
| File tracking | What AI touched | Self-reported | Yes |
| Tool signature | Toolkit was used | Low | Yes (key extractable) |
| Contributor GPG sig | Who attests | High (identity) | No (but content can lie) |
| Provider signature | AI actually used | High | No (doesn't exist) |

---

## The Real Win: Social Norm + Friction

The technical mechanisms matter less than the behavioral shift they enable.

### Current State: No Norm

- No expectation of AI disclosure
- Maintainers guess based on vibes
- Honest contributors have no way to signal transparency
- Gaming is effortless (just don't mention AI)

### With Toolkit Adoption: Norm + Friction

- Projects can say "we expect AI attestation"
- PR without attestation → automatic flag for review
- Honest contributors stand out (attestation = trust signal)
- Gaming now requires:
  1. Understanding the schema
  2. Fabricating plausible prompts
  3. Maintaining consistency across commits
  4. Risk of being caught in inconsistencies

**Cost of honesty:** ~0 (automatic with hooks)

**Cost of gaming:** Non-zero (effort + risk)

The goal isn't to make gaming impossible. It's to make honesty the path of least resistance.

---

## What Maintainers Can Do With This

### Policy Option 1: Transparency Appreciated

> "We appreciate AI attestation but don't require it"

- Labels PRs with attestation
- Gives reviewers context
- No enforcement

### Policy Option 2: Attestation Required for AI Use

> "If you use AI, you must attest. No attestation = assumed human-written."

- Establishes clear norm
- Catches casual non-disclosure
- Contributors who claim human-written but pattern-match as AI get scrutiny

### Policy Option 3: First-Time Contributor Scrutiny

> "First PR from new contributors without attestation gets extra review"

- Targets the drive-by AI spam problem specifically
- Trusted contributors get normal process
- New contributors prove themselves

### Policy Option 4: Attestation-Based Triage

> "PRs with attestation showing focused prompts get priority review"

- Rewards thoughtful AI use
- Punishes spray-and-pray (no attestation = back of queue)
- Incentivizes quality over quantity

---

## The Prompt Visibility Payoff

This is the key insight: **visible prompts are more valuable than hidden prompts**.

### Example 1: Scope Match ✓

```
Prompt: "fix the null check in parser.ts"
PR changes: 1 file, 5 lines
Verdict: ✓ Scope matches, reasonable
```

### Example 2: Scope Mismatch ⚠️

```
Prompt: "fix the null check in parser.ts"
PR changes: 15 files, 800 lines, new dependencies
Verdict: ⚠️ AI hallucinated scope creep, needs scrutiny
```

### Example 3: Vague Prompt ⚠️

```
Prompt: "rewrite auth to be more secure"
PR changes: auth system rewrite
Verdict: ⚠️ Vague prompt → uncertain if AI understood context
```

### Example 4: Debugging Narrative ✓

```
Prompts:
  [1] "the JWT validation is failing on expired tokens"
  [2] "actually the issue is timezone handling"
  [3] "can you add a test that covers the UTC edge case"
PR changes: JWT validation fix + test
Verdict: ✓ Shows debugging process, human was steering
```

The prompts tell a story. A maintainer can read the narrative and judge whether the contributor understood what they were doing.

---

## Summary

| Component | Purpose |
|-----------|---------|
| **Git Notes** | Portable metadata attached to commits, survives repo operations |
| **Tool Signing** | Raises bar for casual forgery, proves toolkit was used |
| **Contributor Signing** | Identity accountability for attestation claims |
| **Provider Signing** | Unforgeable proof (future goal, requires API changes) |
| **Visible Prompts** | Context for reviewers, scope verification, narrative of intent |
| **GitHub Action** | Surfaces attestation in PR workflow, enables policy enforcement |

The technical mechanisms create the foundation. The real value is establishing a norm where transparency is easy and expected, making the honest path the path of least resistance.

---

## The Long Game

This toolkit is a stepping stone:

1. **Now:** Establish convention, prove the workflow, build adoption
2. **Next:** Lobby AI providers (Anthropic, OpenAI) to issue signed receipts
3. **Future:** Unforgeable attestation becomes table stakes for AI-assisted contributions

The schema and workflow we define now becomes the spec providers implement later.
