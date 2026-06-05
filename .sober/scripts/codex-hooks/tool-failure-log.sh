#!/bin/bash
# Codex PostToolUse adapter for Sober's failure logger.
# Codex has PostToolUse for both success and failure; only forward obvious
# failures to the shared Claude-compatible logger.
set -euo pipefail

INPUT=$(cat)
command -v jq >/dev/null 2>&1 || exit 0

STATUS=$(printf '%s' "$INPUT" | jq -r '
  .tool_response.exit_code //
  .tool_response.exitCode //
  .tool_response.status //
  .tool_response.code //
  empty
')
STDERR_MSG=$(printf '%s' "$INPUT" | jq -r '
  .tool_response.stderr //
  .tool_response.error //
  .tool_response.message //
  .error //
  empty
')

# If Codex does not expose a failure-shaped response, do not log a false failure.
if [ -z "$STATUS" ] && [ -z "$STDERR_MSG" ]; then exit 0; fi
case "$STATUS" in 0|success|ok|true) exit 0 ;; esac

printf '%s' "$INPUT" | jq --arg err "${STDERR_MSG:-tool failed}" '. + {error: $err}' \
  | "${SOBER_HOME:-$HOME/.sober}/scripts/hooks/tool-failure-log.sh"
