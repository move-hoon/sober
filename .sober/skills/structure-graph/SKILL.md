---
name: structure-graph
description: GitNexus is a conditional accelerator, not a default navigation tool. Use it early only when the task already signals large-repo, cross-module, blast-radius, or unclear-flow uncertainty. Every candidate must be verified with rg/Probe before reading deeply or editing.
---

# Structure Graph Skill (Conditional Accelerator)

## Purpose
GitNexus is **not** a routine navigation tool, but rather a **conditional accelerator** to narrow down candidates early when dealing with structural or dependency uncertainties. To minimize context bloat and prevent reasoning pollution, all candidates returned by GitNexus must be verified *before* reading them deeply or editing them.

---

## When to Use (and when not to)
*   **Use early** if the task involves:
    *   Large, unfamiliar codebases or unclear flow entry points.
    *   Cross-cutting module changes or DTO/API/Event/Config/Interface changes.
    *   Analyzing the "blast radius" (downstream impact) of a proposed change.
*   **Do NOT use** for:
    *   Small, localized, or well-defined tasks (e.g., finding a class or simple keyword). Use the regular search ladder (`ripgrep` / `Probe` only) to keep the context clean.

---

## Tool Division (ADR-006)
*   **`ripgrep` / `Probe` (Ground Truth):** Always the final source verification.
*   **`GitNexus` (Code Structure Candidate Generator):** Best for compile-time topology (imports, symbols, call graphs, static dependencies).
*   **`Graphify` (Multimodal/Non-code Graph):** Used only when query needs non-code context (docs, PDFs, diagrams, architecture notes).
*   **Tests / Framework Evidence (Runtime Confirmation):** Critical for dynamic runtime wiring (Spring DI, AOP, events, `@Conditional` beans, reflection), which static graphs cannot prove.

---

## How it Works
1.  **Generate Candidates:** Run GitNexus CLI to generate structure hints. Use Graphify only when the task requires non-code context such as docs, PDFs, diagrams, or architecture notes.
2.  **Verify Before Reading Deeply:** Run a quick `ripgrep` or `Probe` to verify the candidate exists and is relevant:
    ```bash
    rg -n "candidateSymbol" path/from/graph
    ```
3.  **Targeted Reading & Optional Edits:** Open and read only the verified files. Edit only if the task requires it.
4.  **Runtime Validation:** Confirm dynamic behavior using compilation and test suites.

---

## Rules
- **GitNexus is a conditional accelerator, not a default navigation tool.**
- **GitNexus output is a candidate list, not evidence.** Every candidate must be verified with `rg`/Probe before reading deeply or editing.
- Keep graph tools off the default path; their absence must not block work.
- Prefer read-only GitNexus operations. Do not use graph output as edit authority.
- Treat runtime-flow results as lower-confidence; confirm Spring DI, AOP, events, `@Conditional` beans, reflection, and config-driven behavior with tests or framework-aware evidence.
- Prefer GitNexus CLI over GitNexus MCP by default. GitNexus MCP is opt-in only; do not keep it attached as an always-on context provider unless the user explicitly requests it.
- When running `gitnexus analyze`, preserve Sober's custom spine and skills and avoid embedding cost by default:
  - use `gitnexus analyze --skip-agents-md --skip-skills --skip-embeddings`, or
  - configure `"skipContextFiles": true`, `"skipSkills": true`, and `"embeddings": false` in `.gitnexusrc`:
    ```json
    {
      "skipContextFiles": true,
      "skipSkills": true,
      "embeddings": false
    }
    ```

