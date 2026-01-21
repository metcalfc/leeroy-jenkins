# The Idea

## Today: Personal Transparency

Right now, if you want to be transparent about using AI in your open source contributions, you can just... say so. This toolkit automates that:

```
commit abc1234
Author: developer@example.com

    Fix null check in parser

    [leeroy]
    Tool: claude-code/1.0.32
    Model: claude-sonnet-4-20250514
    Prompts:
      [14:20] fix the null check in parser.ts
      [14:22] also handle empty array case
```

That's it. You used Claude Code version X with model Y and these prompts. Anyone reviewing your commit can see that.

**What this gets you:**
- Transparency about your workflow
- Context for reviewers ("oh, they iterated on this")
- A record of what you asked the AI to do

**What this doesn't get you:**
- Any proof you're telling the truth
- Any enforcement
- Any guarantee the attestation survives rebasing

This is fine! It's just opt-in transparency for people who want to be upfront about their process.

## Why Git Notes (for now)

We used git notes because they're already there. No GitHub dependency, works with any git host, can be queried with standard git commands.

But git notes have real problems:
- They're attached to commit SHAs
- Rebase, amend, cherry-pick → attestation is orphaned
- Not well supported by GitHub/GitLab UI

So git notes are a **demo mechanism**, not the solution.

## Tomorrow: What Real Support Would Look Like

For this to actually work at scale, you'd need:

### 1. Version Control Support

Git (or JJ, or whatever comes next) would need native metadata that survives history rewriting:
- Cherry-picks preserve attestation
- Rebases preserve attestation  
- Amends preserve attestation

This is nontrivial. The metadata needs to be tied to the *content* somehow, not just the SHA.

### 2. Platform Support

GitHub, GitLab, etc. would need to:
- Accept and display this metadata
- Let projects set policies ("require attestation for PRs")
- Surface it in the review UI

### 3. Hardware Attestation (the interesting part)

Here's where it gets actually useful: YubiKey or similar hardware tokens.

If you sign your commits with a key that lives on a hardware device, you can prove:
- The signing key came from hardware (there are ways to attest this)
- A human had to physically touch the device to sign

This doesn't prove you wrote the code, but it proves a human was present in the loop. Combined with attestation metadata, you start to get something meaningful:
- "This commit was signed by a hardware key" (human present)
- "The attestation says AI was used with these prompts" (context)

That's a much better foundation for trust than "the commit message says they used AI."

### 4. Provider Signatures (future)

Eventually, AI providers (Anthropic, OpenAI, etc.) could sign their outputs. Then you'd have:
- Hardware key: proves human was present
- Provider signature: proves AI actually generated this output

But that doesn't exist yet.

## Summary

| Timeframe | What Works | What Doesn't |
|-----------|-----------|--------------|
| **Today** | Self-reported transparency in commits | No proof, breaks on rebase |
| **Tomorrow** | Would need Git/JJ + GitHub/GitLab support | Significant tooling work |
| **Eventually** | Hardware attestation + provider signatures | Doesn't exist yet |

This POC shows what the **format and workflow** could look like. Making it actually reliable requires work from the version control and platform folks.
