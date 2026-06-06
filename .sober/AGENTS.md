# Sober — Agent Policy Spine

Shared contract for Claude Code (Pro) and Codex CLI (Plus). Loaded every turn — keep it compact.

## Prime directive
Cage the LLM to irreducible judgment. Offload search, edit, and bulk output to deterministic tools. Keep failures isolated and recoverable.

**Invariant:** every LLM action must be cheap to verify and cheap to roll back.

## Engineering guardrails (every change)
1. **No assumptions** — state them or ask. Don't invent requirements.
2. **No over-engineering** — smallest change to satisfy the ask; no speculative abstraction.
3. **No orthogonal edits** — touch only what the task needs; surface unrelated issues separately.
4. **Match surrounding code** — naming, idiom, structure, comment density.

## Policies P0–P8
- **P0 Context** — never read whole files; report `file:line` + ~2 lines. Pipe search to `| head`. Compact past ~60% context.
- **P1 Search** — never hand-grep. `ripgrep` → `Probe` (structural) → semantic (`mgrep`) for concepts, last resort.
- **P2 Edit** — repeated edits via `ast-grep --rewrite`; type-aware single-symbol via Serena `replace_symbol`. Minimize LLM rewrites.
- **P3 Verify** — no state change from unverified navigation. Before deep-reading graph candidates or making multi-file changes: verify candidate/site with `ripgrep`, `Probe`, or Serena (one deterministic call, not LLM reasoning), then compile/test.
- **P4 Budget** — turn caps (search 1, edit 1-2, debug 3). 3 failed hypotheses → stop and re-plan. Never loop on the same guess.
- **P5 Memory** — write session state/next steps to HANDOFF.md (recent only); persistent architectural facts to .serena/memories. Human reviews before next session. No auto-execution or blind injection.
- **P6 Isolation** — reversible (git) boundaries. Use subagents/worktree for independent work (3+ parallel tasks, repo-scale explore, fresh review/pre-commit). Don't over-parallelize light work.
- **P7 Observe** — justify additions by measurement; roll back if a metric worsens.
- **P8 Compression** — No verbose prose/file reprints. Format: result + changed files + test outcome only. Use caveman if loaded.

## Tooling posture

CLI first: `ripgrep` (lexical) → `Probe` (structural) → Serena (symbol/LSP). Use structure graph (`GitNexus` CLI) only as a conditional accelerator (large/unfamiliar repos, cross-module flow, unclear entry points, or blast-radius); verify candidates with `rg`/Probe before deep reading or editing. Semantic (`mgrep`) for concept queries only, last resort. `ast-grep` exclusively for rewrites. **Tools are optional — absence must not break base operation.**

Prefer CLI by default. MCP is opt-in only. For GitNexus, prefer CLI-generated graph artifacts/hints over MCP to control cost/context. Reasoning uses native extended thinking; research uses native WebSearch; library docs via `ctx7` when present — don't trust stale API memory.

---
Read by Codex directly, Claude via `CLAUDE.md`. Self-contained spine; skills carry tool specifics. (Directory READMEs are human docs, not agent context.)
