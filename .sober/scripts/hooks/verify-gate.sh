#!/bin/bash
# verify-gate.sh - PreToolUse Hook (Bash) — WARN MODE, backs P3.
# Reminds to run scripts/verify.sh before a commit/push when the working tree
# carries code changes. Advisory only: it NEVER blocks (no permissionDecision).
# Enforcement of dangerous commands stays in critical-action-check.sh.
set -euo pipefail

INPUT=$(cat)

command -v jq >/dev/null 2>&1 || exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0

# Only gate the verification boundary: committing or pushing.
case "$CMD" in
  *"git commit"*|*"git push"*) ;;
  *) exit 0 ;;
esac

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Skip if not a git repo. Language-agnostic: instead of whitelisting code
# extensions (which silently skips C#/PHP/Swift/Dockerfile/Terraform/…), we
# warn whenever any changed file is NOT pure prose/docs. Anything that isn't a
# doc is treated as worth verifying — no language list to fall out of date.
git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1 || exit 0
CHANGED=$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null \
  | sed 's/^...//' \
  | grep -vEi '\.(md|markdown|mdx|txt|rst|adoc)$|^LICENSE|(^|/)docs/' \
  | grep -c . || true)
[ "${CHANGED:-0}" -eq 0 ] && exit 0

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "[VERIFY-GATE/warn] P3: ${CHANGED} code file(s) changed. Run ~/.sober/scripts/verify.sh (compile/test) before this commit/push. Advisory only — not blocking."
  }
}
EOF

exit 0
