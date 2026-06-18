#!/bin/bash
# Codex PostToolUse adapter for Sober's failure logger.
# Codex has PostToolUse for both success and failure; only forward obvious
# failures to the shared Claude-compatible logger.
set -euo pipefail

INPUT=$(cat)
[ -z "${INPUT:-}" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0
printf '%s\n' "$INPUT" | jq -e . >/dev/null 2>&1 || exit 0

STATUS=$(printf '%s' "$INPUT" | jq -r '
  (.tool_response | objects | .exit_code // .exitCode // .status // .code) // empty
')
STDERR_MSG=$(printf '%s' "$INPUT" | jq -r '
  ((.tool_response | objects | .stderr // .error // .message) // .error) // empty
')

# If Codex does not expose a failure-shaped response, do not log a false failure.
if [ -z "$STATUS" ] && [ -z "$STDERR_MSG" ]; then exit 0; fi
case "$STATUS" in 0|success|ok|true) exit 0 ;; esac

printf '%s' "$INPUT" | jq --arg err "${STDERR_MSG:-tool failed}" '. + {error: $err}' \
  | "${SOBER_HOME:-$HOME/.sober}/scripts/hooks/tool-failure-log.sh"
