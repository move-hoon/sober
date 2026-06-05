# ADR-007 — Output compression

Status: Accepted for Sober v2 planning. Quantitative claims remain hypotheses until local measurement.

## Decision
Control output tokens with concise style/Caveman-like modes; output also consumes quota.

## Drivers
- Verified result per quota.
- Long-term maintainability across languages/frameworks.
- Reversibility and safety.

## Consequences
- Keep implementation small and staged.
- Prefer detection/guidance over mandatory unmeasured dependencies.
- Record local evidence before claiming improvement.
