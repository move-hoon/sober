# ADR-006 — Conditional structure graph

Status: Accepted for Sober v2 planning. Quantitative claims remain hypotheses until local measurement.

## Decision
Treat GitNexus/CRG/Graphify-style graphs as hints for large repos, not verified truth.

## Drivers
- Verified result per quota.
- Long-term maintainability across languages/frameworks.
- Reversibility and safety.

## Consequences
- Keep implementation small and staged.
- Prefer detection/guidance over mandatory unmeasured dependencies.
- Record local evidence before claiming improvement.
