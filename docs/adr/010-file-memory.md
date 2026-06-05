# ADR-010 — File-based memory

Status: Accepted for Sober v2 planning. Quantitative claims remain hypotheses until local measurement.

## Decision
Use reviewed local files/HANDOFF/.serena memories; reject product-style memory stacks for core.

## Drivers
- Verified result per quota.
- Long-term maintainability across languages/frameworks.
- Reversibility and safety.

## Consequences
- Keep implementation small and staged.
- Prefer detection/guidance over mandatory unmeasured dependencies.
- Record local evidence before claiming improvement.
