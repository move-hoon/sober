---
name: search-ladder
description: Offload code search to deterministic tools instead of hand-grepping or reading whole files (P1). Climb the ladder lexical → structural → semantic, stopping at the first rung that answers. Use whenever locating symbols, call sites, definitions, or concepts in a repo.
---

# Search Ladder Skill (P1)

## Purpose
Never hand-grep, never read a whole file to "look around." Each search is one offloaded call whose result is `file:line` + ~2 lines (P0/P8). Climb only as far as needed.

## The ladder (stop at first rung that answers)
1. **Lexical — `ripgrep`** (default). Exact strings, identifiers, regex.
   ```bash
   rg -n "createSession" --type ts | head -50
   rg -n "TODO|FIXME" -g '!*.test.*' | head -50
   ```
2. **Structural — Probe** (when code structure matters more than exact text).
   ```bash
   probe search "auth middleware" ./src
   ```
3. **Semantic — `mgrep`** — concept queries only, **last resort** (cost + noise).
   ```bash
   mgrep "where is rate limiting enforced" src/
   ```

## Rules
- Pipe high-frequency searches to `| head` — bounded output (P0).
- Prefer structural search over regex when text is too brittle.
- Drop to semantic only when you cannot name the token — never as rung 1.
- Optional tools may be absent; fall back down the ladder (`probe` missing → `rg`).

Need concrete recipes for a rung (regex flags, Probe queries, mgrep phrasing)? Read `references/ladder.md`.
