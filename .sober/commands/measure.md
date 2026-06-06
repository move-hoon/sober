---
name: measure
description: Capture L6 cost/context KPIs (P7) before and after a harness change, and roll back anything that regresses. Use when adding a tool/skill/hook or evaluating a build phase.
argument-hint: [baseline|after|<label>]
---

# /measure Command

Peak KPI = **verified results / quota**. No addition is justified by intuition (P7).

## What to capture
$ARGUMENTS

Read these and record the numbers:
- `/context` — peak context fill %, token budget
- `/cost` — output tokens, message count
- `/status` — session totals
- `~/.sober/logs/tool-failures.log` — retry rate, failure patterns

Plus from the session: files read / task, turn count, failure blast radius (files touched per failed change).

## Flow
1. `baseline` — record metrics on a fixed sample task **before** the change.
2. Apply exactly **one** change (tool / skill / hook).
3. `after` — re-run the same sample task, record metrics.
4. **Gate**: any single metric regresses → roll back (git boundary). One change at a time, measured.

## Output
```
## KPI: [label]
| metric            | baseline | after | Δ |
|-------------------|----------|-------|---|
| files read/task   |          |       |   |
| output tokens     |          |       |   |
| peak fill %       |          |       |   |
| messages          |          |       |   |
| retry rate        |          |       |   |

Verdict: keep / roll back
```

Keep a short before/after note in `HANDOFF.md` (P5) — not auto-injected. See `skills/observe`.
