---
name: structure-graph
description: Conditional last resort for large repos where the search ladder cannot trace a flow — use a structure/dependency graph (GitNexus, code-review-graph) as a hint, then verify the hint with a normal search before acting. Do not use for routine navigation.
---

# Structure Graph Skill (conditional)

## When to use (and only then)
- Large/unfamiliar repo where `ripgrep` → Probe (search-ladder) cannot trace a call/data flow.
- You need a map (module dependencies, call graph, blast radius) before a cross-cutting change.

**Not** for routine navigation — that stays on the search ladder (P1). This is opt-in, large-repo only.

## Tool choice (ADR-006)
- **Structure / "what & where"** (module deps, call graph, blast radius) → **GitNexus** or **code-review-graph** — the default for repo-structure questions.
- **Multimodal / "why"** (docs, PDFs, diagrams alongside code) → **Graphify** — only when the question needs non-code context, not plain structure.
- All are **static** graphs: they miss runtime wiring (Spring DI/AOP/@Async/events) — weakest exactly where it's interesting. So: hint only, verify before acting.

## How
1. Generate or query a structure graph (GitNexus / code-review-graph for structure; Graphify for multimodal "why") to get a **hint** — candidate files, edges, an entry point.
2. **Verify the hint** with a normal search before acting:
   ```bash
   rg -n "candidateSymbol" path/from/graph
   ```
3. Act only on verified locations. The graph is a lead, never ground truth (P3).

## Rules
- Graph output is a hint to narrow search — confirm every node with `rg`/Probe before editing.
- Keep it off the default path; absence of any graph tool must not block work (degrade to search ladder).
- One change behind a git boundary; verify after (P6/P7).
