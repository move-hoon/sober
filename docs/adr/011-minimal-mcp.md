# ADR-011 — Minimal MCP

Status: Accepted for Sober v2 planning. Quantitative claims remain hypotheses until local measurement.

## Decision
Prefer CLI tools; keep MCP minimal — **zero MCP loaded by default**. Serena (LSP) is the only opt-in MCP. `sequential-thinking` (→ native extended thinking) and `perplexity` (→ native WebSearch) were dropped: native capability absorbs them (ADR-013), so neither ships as a default MCP.

## Drivers
- Verified result per quota.
- Long-term maintainability across languages/frameworks.
- Reversibility and safety.

## Consequences
- Keep implementation small and staged.
- Prefer detection/guidance over mandatory unmeasured dependencies.
- Record local evidence before claiming improvement.
