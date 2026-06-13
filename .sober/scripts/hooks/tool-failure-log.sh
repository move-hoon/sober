#!/bin/bash
# tool-failure-log.sh - PostToolUseFailure Hook
# Logging and escalation recommendations on tool failure (0 tokens)
# Hardened Hook

set -euo pipefail

# Check jq dependency
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
[ -z "${INPUT:-}" ] && exit 0
printf '%s\n' "$INPUT" | jq -e . >/dev/null 2>&1 || exit 0

# Parsing
TOOL_NAME=$(printf '%s\n' "$INPUT" | jq -r '.tool_name // "unknown"')
ERROR_MSG=$(printf '%s\n' "$INPUT" | jq -r '.error // "unknown error"')
SESSION_ID=$(printf '%s\n' "$INPUT" | jq -r '.session_id // "unknown"')

LOG_FILE="${SOBER_TOOL_FAILURE_LOG:-$HOME/.sober/logs/tool-failures.log}"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Record log. Best-effort redact common credential shapes, collapse newlines,
# then truncate — so a secret in the error body is not persisted to the local
# log file verbatim (full errors are still visible in-session).
ERROR_MSG=$(printf '%s' "$ERROR_MSG" | tr '\n' ' ' | sed -E \
  -e 's/(sk-|ghp_|gho_|github_pat_|xox[baprs]-|AKIA|ASIA|AIza)[A-Za-z0-9_-]+/[REDACTED]/g' \
  -e 's/([Bb]earer )[A-Za-z0-9._-]+/\1[REDACTED]/g' \
  -e 's/(([Aa]pi[_-]?[Kk]ey|[Tt]oken|[Ss]ecret|[Pp]assword|[Aa]uthorization)["'"'"']?[[:space:]]*[:=][[:space:]]*)[^[:space:]]+/\1[REDACTED]/g' \
  -e 's/eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/[REDACTED_JWT]/g')
ERROR_MSG="${ERROR_MSG:0:200}"
{
  echo "[$TIMESTAMP] Tool: $TOOL_NAME | Error: $ERROR_MSG | Session: $SESSION_ID" >> "$LOG_FILE"
} 2>/dev/null || exit 0

# Count how many of the most recent failures were this same tool — a bounded
# recency window (last 20 entries), fixed-string match on the delimited Tool
# field so regex/substring quirks in the tool name can't skew the count.
RECENT_FAILURES=$(tail -n 20 "$LOG_FILE" 2>/dev/null | grep -Fc "Tool: $TOOL_NAME |" || true)
RECENT_FAILURES=${RECENT_FAILURES:-0}

# Recommend escalation when this tool fails repeatedly in the recent window
if [ "$RECENT_FAILURES" -ge 3 ]; then
  echo "[ToolFailure] Tool $TOOL_NAME failed ${RECENT_FAILURES} times. Re-plan recommended (native plan mode)." >&2
fi
