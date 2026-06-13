#!/bin/bash
# session-start.sh - SessionStart Hook
# 1. Set environment variables (using CLAUDE_ENV_FILE)
# 2. Notify previous session context (opt-in: CLAUDE_SESSION_NOTIFY=1)
# Official Docs: Environment variables can be persisted via CLAUDE_ENV_FILE in SessionStart
set -euo pipefail

# 1. Set environment variables (0 tokens) - Always runs
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  # Example: project-specific environment variables
  # echo 'export NODE_ENV=development' >> "$CLAUDE_ENV_FILE"
  # echo 'export DEBUG=true' >> "$CLAUDE_ENV_FILE"
  
  # Load .env.local if exists (Security: values are not exposed)
  ENV_LOCAL="${CLAUDE_PROJECT_DIR:-.}/.env.local"
  if [ -f "$ENV_LOCAL" ]; then
    # Extract only variable names and export (values are loaded at runtime).
    # Read the file directly (no grep pipeline) so a file with only comments or
    # blank lines doesn't fail the hook under `set -o pipefail`. Security: emit
    # only syntactically valid names — lines with `export `, spaces, quotes, or
    # command substitution fail the regex and are skipped, so a crafted
    # .env.local cannot poison the sourced env file.
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in \#*|'') continue ;; esac     # skip comments / blank lines
      case "$line" in *=*) ;; *) continue ;; esac   # require an assignment
      var_name="${line%%=*}"
      if [[ "$var_name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        echo "export $var_name=\"\${$var_name:-}\"" >> "$CLAUDE_ENV_FILE"
      fi
    done < "$ENV_LOCAL"
  fi
fi

# 3. Failure log notification (opt-in, ~30 tokens)
if [ "${CLAUDE_FAILURE_NOTIFY:-0}" = "1" ]; then
  LOG_FILE="${SOBER_TOOL_FAILURE_LOG:-$HOME/.sober/logs/tool-failures.log}"
  if [ -f "$LOG_FILE" ]; then
    FAILURE_COUNT=$(wc -l < "$LOG_FILE" 2>/dev/null | tr -d ' ')
    if [ "$FAILURE_COUNT" -gt 10 ]; then
      cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "⚠️ ${FAILURE_COUNT} tool failures accumulated. To analyze: /analyze-failures"
  }
}
EOF
    fi
  fi
fi

# 3b. Handoff notice (opt-in, ~20 tokens) — P5: notify, never auto-inject body.
if [ "${CLAUDE_HANDOFF_NOTIFY:-0}" = "1" ]; then
  HANDOFF="${CLAUDE_PROJECT_DIR:-.}/HANDOFF.md"
  if [ -f "$HANDOFF" ]; then
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "📝 HANDOFF.md from last session exists. Load deliberately if resuming: Read HANDOFF.md"
  }
}
EOF
  fi
fi

# 4. Message budget reminder (always-on, ~40 tokens)
cat <<'BUDGET'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "📊 Pro Plan (rough guidance — verify with /measure, don't treat as fact):\n• ~45 msg/5h is a heuristic target, not a guarantee\n• Default: just ask — the spine batches plan+build+verify\n• Complex: native plan mode for 4+ files\n• Approx relative cost: Haiku < Sonnet < Opus; output costs more than input"
  }
}
BUDGET

exit 0
