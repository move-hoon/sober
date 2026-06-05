#!/bin/bash
# compact-suggest.sh - PostToolUse Hook (After Edit/Write completion)
# 3-tier progressive warnings for context growth management
# Tier 1: 25 (advisory) | Tier 2: 50 (warning) | Tier 3: 75 (critical)
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"')
# Sanitize before using in a /tmp path — defensive against path traversal / odd chars.
SAFE_SESSION_ID=$(printf '%s' "$SESSION_ID" | tr -c 'A-Za-z0-9._-' '_')

COUNTER_FILE="/tmp/claude-tool-count-$SAFE_SESSION_ID"

# Increment counter
count=$(($(cat "$COUNTER_FILE" 2>/dev/null || echo 0) + 1))
echo "$count" > "$COUNTER_FILE"

# Tier 1: Advisory (25 tool calls)
if [ "$count" -eq 25 ]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "[COMPACT-ADVISORY] 25 tool calls. Context growing — consider /compact at next logical break."
  }
}
EOF
fi

# Tier 2: Warning (50 tool calls)
if [ "$count" -eq 50 ]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "[COMPACT-WARNING] 50 tool calls. Quota burn rate increasing — run /compact before next task."
  }
}
EOF
fi

# Tier 3: Critical (75 tool calls — approaching auto-compact at 75% context)
if [ "$count" -eq 75 ]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "[COMPACT-CRITICAL] 75 tool calls. High context — /compact NOW, or start a fresh session (HANDOFF.md is written on Stop)."
  }
}
EOF
fi

exit 0
