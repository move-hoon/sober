# ADR-008 — Verification gate

Status: Accepted for Sober v2 planning. Quantitative claims remain hypotheses until local measurement.

## Decision
Do not mutate from unverified navigation; cross-check targets and run compile/tests where applicable.

## Drivers
- Verified result per quota.
- Long-term maintainability across languages/frameworks.
- Reversibility and safety.

## Consequences
- Keep implementation small and staged.
- Prefer detection/guidance over mandatory unmeasured dependencies.
- Record local evidence before claiming improvement.
