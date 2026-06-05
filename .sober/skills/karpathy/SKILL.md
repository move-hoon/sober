---
name: karpathy
description: Engineering guardrails for every change — the behavioral base of the policy spine. Make no unrequested assumptions, no over-engineering, no orthogonal edits, and match the surrounding code. Apply on every edit, plan, and review.
---

# Karpathy Guardrails Skill (spine base)

The behavioral foundation under P0–P8 ([`AGENTS.md`](../../../AGENTS.md)). These four catch the failures that quietly burn the most quota: invented requirements, 50→500-line over-builds, unrelated churn, and code that fights the codebase's style.

## The four guardrails (every change)

1. **No unrequested assumptions.** Build what was asked. If a requirement is ambiguous, state your assumption inline or stop and ask — don't invent scope.
2. **No over-engineering.** The smallest change that satisfies the ask. No speculative abstraction, no "while I'm here" framework. A 5-line fix stays 5 lines.
3. **No orthogonal edits.** Touch only what the task needs. Surface unrelated issues separately (a note, a follow-up) — never fold them into this diff.
4. **Match the surrounding code.** Naming, idiom, structure, comment density, error handling — read like the file you're editing, not like a new author.

## How to apply

- **Before editing:** restate the ask in one line. If your plan adds files/abstractions the ask didn't call for, cut them (guardrail 2).
- **While editing:** keep the diff minimal and local (guardrails 1, 3). Mirror the nearest existing pattern (guardrail 4).
- **Before finishing:** scan the diff — any line not traceable to the ask is an orthogonal edit; pull it out.

## Why this is the base

Ecosystem adoption shows the biggest win is a behavioral contract, not a tool. These guardrails make every LLM action **cheap to verify and cheap to roll back** (the invariant): a minimal, on-style, scope-true diff is trivial to review and revert. Everything in P0–P8 builds on this.
