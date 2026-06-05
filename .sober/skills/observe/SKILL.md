---
name: observe
description: Measure cost and context before justifying any harness change (L6 / P7). Read /context, /cost, /status and the tool-failure log to get before/after numbers; roll back anything that worsens a metric. Use when adding tools, evaluating a phase, or diagnosing quota burn.
---

# Observe Skill (L6 — peak KPI = verified results / quota)

## Purpose
No addition is justified by intuition. Every tool, skill, or hook must pay for itself in a measured metric; if a change worsens a number, revert it (P7).

## Metrics to capture
| Metric | Source |
|---|---|
| Files read / task | session transcript count |
| Output tokens | `/cost` |
| Peak context fill % | `/context` |
| Message count | `/cost`, `/status` |
| Turn count | session |
| Retry rate | tool-failure log |
| Failure blast radius | files touched per failed change |

## Workflow (per phase / per addition)
1. **Baseline** — record metrics on a fixed sample task *before* the change.
2. **Change** — apply one thing (a tool, a skill, a hook).
3. **After** — re-run the same sample task, record metrics.
4. **Gate** — any single metric regresses → roll back the change (git boundary).

## Inputs
- `/context` — token budget + peak fill.
- `/cost`, `/status` — messages, output tokens.
- `scripts/hooks/tool-failure-log.sh` output — retries, failure patterns.

## Rule
One change at a time, measured. Bundled changes hide which one regressed. Keep a short before/after note in `.claude/HANDOFF.md` (P5), not auto-injected.

## Measured escalations (don't adopt by default)
Default memory is file-based (`HANDOFF.md` + `.serena/memories`). Only if a metric shows it's insufficient: **claude-mem** (auto session memory) — watch for auto-injection noise. Adopt via the before/after gate above, never preemptively (ADR-010/P7).
