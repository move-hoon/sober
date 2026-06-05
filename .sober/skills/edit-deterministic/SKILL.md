---
name: edit-deterministic
description: Offload mechanical and type-aware edits to deterministic tools instead of LLM file-rewrites (P2). Use ast-grep --rewrite for repeated/mechanical transforms and Serena replace_symbol for single type-aware symbol edits. Apply whenever a change is rule-shaped rather than judgment-shaped.
---

# Deterministic Edit Skill (P2)

## Purpose
Minimize LLM file-rewrites. If an edit follows a rule, a tool should apply it — verifiably and reversibly (invariant: cheap to verify, cheap to roll back).

## Decision
- **Mechanical / repeated across many sites** → `ast-grep --rewrite` (preview first).
- **Single, type-aware symbol** (rename/replace a function/method body) → Serena `replace_symbol`.
- **Genuine judgment** (novel logic, one-off) → LLM `Edit`, smallest diff, match surrounding code.

## ast-grep --rewrite (mechanical)
```bash
# ALWAYS dry-run first — no -U/--update-all
ast-grep -p 'foo($A)' --rewrite 'bar($A)' --lang ts        # preview diff
ast-grep -p 'foo($A)' --rewrite 'bar($A)' --lang ts -U     # apply after review
```

## Serena (type-aware, single symbol)
- `find_symbol` → locate the exact symbol (no whole-file read).
- `replace_symbol_body` → swap one definition, LSP-aware.
- Single MCP; use only when enabled. Absent → fall back to scoped `Edit`.
- Large repos: `serena project index` first; turn it off for tiny modules (startup cost).
- **Kotlin escape hatch (ADR-005)** — Serena's standard LSP can be flaky on Kotlin (slow startup). For deep Kotlin/Spring symbol work, the IntelliJ/JetBrains backend is the gold standard; switch to it only when the standard LSP misbehaves (it's paid + IDE-bound, so not the default).
- Verified findings worth keeping go to `.serena/memories` (human-reviewed, P5) — not auto-injected.

## Rules
- Preview every `--rewrite` before applying; commit boundary around it (P6).
- Re-confirm target in one shot before a multi-site change (P3), then verify (`scripts/verify.sh`).
- Optional tools may be absent — degrade to a minimal manual `Edit`, never block.

Need rewrite/replace patterns and worked examples? Read `references/patterns.md`.
