# Sober — Agent Policy Spine

Shared contract for **Claude Code (Pro)** and **Codex CLI (Plus)**. Both runtimes read this file. Keep it short — it loads every turn.

## Prime directive
Cage the LLM to irreducible judgment. Offload search, transformation, and bulk output to deterministic tools. Make failure isolated and recoverable.

**Invariant:** every LLM action must be cheap to verify and cheap to roll back.

## Engineering guardrails (every change)
1. **No unrequested assumptions** — state them, or stop and ask. Don't invent requirements.
2. **No over-engineering** — the smallest change that satisfies the ask. No speculative abstraction.
3. **No orthogonal edits** — touch only what the task needs; surface unrelated issues separately.
4. **Match the surrounding code** — naming, idiom, structure, comment density.

## Policies P0–P8
- **P0 Context discipline** — never read whole files; report `file:line` + ~2 lines. Pipe high-frequency search to `| head`. Compact past ~60% context fill.
- **P1 Search offload** — never hand-grep. `ripgrep` → `Probe` (structural repo-search) → semantic (`mgrep`) only for concept queries, last resort.
- **P2 Edit offload** — mechanical/repeated edits via `ast-grep --rewrite`; type-aware single-symbol via Serena `replace_symbol`. Minimize LLM file-rewrites.
- **P3 Verification gate** — no state change from unverified navigation. Before a multi-file change: verify the edit site with ripgrep or Serena (one deterministic call, not LLM reasoning), then compile/test.
- **P4 Failure budget** — turn caps (search 1, edit 1–2, debug 3). Three failed hypotheses → stop and re-plan. Never loop on the same guess.
- **P5 Persistent memory** — record only verified findings. Write session state/next steps to HANDOFF.md (keep it compact, recent only); write persistent architectural facts to .serena/memories. Human reviews before the next session picks them up. No auto-execution, no blind auto-injection.
- **P6 Failure isolation** — reversible (git) boundaries. Use **native subagents/worktree** for truly independent work (3+ parallel tasks, repo-scale explore, fresh review/pre-commit) — borrow, don't build a chain; don't over-parallelize light work.
- **P7 Observation** — justify every addition by measurement; roll back any change that worsens a metric.
- **P8 Output compression** — No verbose prose. No whole-file reprints. Output format: result + changed files + test outcome only. Use the caveman skill if loaded.

## Tooling posture
Deterministic CLI first: `ripgrep` (lexical) → `Probe` (structural search) → Serena (symbol/LSP) → semantic last. Use `ast-grep` exclusively for rewrites. **These are optional — their absence must not break base operation.** Prefer CLI tools over MCP tools when both can do the job. Reasoning uses native extended thinking; research uses native WebSearch; current library docs via Context7/`ctx7` when present — don't trust stale API memory.

---
Read by both runtimes — Codex reads `AGENTS.md` directly; Claude reads it via `CLAUDE.md` (a symlink to this file). This spine is self-contained; the loaded skills carry any tool specifics. (Directory READMEs are human docs, not agent context.)
