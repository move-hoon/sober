---
name: analyze-failures
description: Analyze accumulated tool failure logs to extract recurring patterns and suggest improvements.
argument-hint: [limit] (default: 50)
disable-model-invocation: false
---

# /analyze-failures Command

Analyze tool failure logs to identify recurring errors and surface durable lessons worth recording.

## Input
- `limit` (optional): Number of recent failures to analyze. Default is 50.

## Execution
Run the bash script to parse `~/.sober/logs/tool-failures.log`:

```bash
bash ~/.sober/scripts/analyze-failures.sh "$ARGUMENTS"
```

## How It Works
1. **Collection**: Failures are automatically logged by `~/.sober/scripts/hooks/tool-failure-log.sh` (Zero-cost).
2. **Analysis**: This command uses `awk` to aggregate and count errors locally (Zero-cost for generation).
3. **Insight**: The output summary is added to context, allowing Claude to offer specific advice if needed.

## Output Example
```markdown
## Failure Analysis

**Total failures logged**: 120
**Analyzing last**: 50

### Top Failures
1. **Edit tool**: "old_string not found" (15 failures)
2. **Grep tool**: "pattern syntax error" (8 failures)

### Most Problematic Tools
- **Edit tool**: 25 failures
- **Grep tool**: 12 failures

💡 **Recommendations**:
- Review frequent failures and update your approach
- Record any durable lesson in `.claude/HANDOFF.md` (human-reviewed memory, P5)
```

This command is **quantitative**: it looks at *past errors* from the logs ("what went wrong?") so you can stop repeating them (P4). Keep lessons in `HANDOFF.md`, not auto-memory.
