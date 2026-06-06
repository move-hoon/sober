#!/bin/bash
# handoff-write.sh - Stop Hook — bounded session continuity memory (P5).
# Overwrites HANDOFF.md with a fresh, compact snapshot of where the
# session left off. Bounded to ~4000 bytes. Human-reviewed, not auto-injected.
set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
[ -z "${INPUT:-}" ] && exit 0
printf '%s\n' "$INPUT" | jq -e . >/dev/null 2>&1 || exit 0

STOP_ACTIVE=$(printf '%s\n' "$INPUT" | jq -r '.stop_hook_active // false')
[ "$STOP_ACTIVE" = "true" ] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1 || exit 0

OUT_DIR="$PROJECT_DIR"
OUT="$OUT_DIR/HANDOFF.md"
mkdir -p "$OUT_DIR"

BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo "?")
LAST=$(git -C "$PROJECT_DIR" log -1 --pretty='%h %s' 2>/dev/null || echo "(no commits)")
CHANGED=$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null | head -20)
TS=$(date '+%Y-%m-%d %H:%M')

{
  echo "# HANDOFF — session continuity (auto, bounded; human-reviewed per P5)"
  echo
  echo "_Updated: ${TS}_"
  echo
  echo "- Branch: \`${BRANCH}\`"
  echo "- Last commit: ${LAST}"
  echo
  echo "## Uncommitted changes"
  if [ -n "$CHANGED" ]; then
    echo '```'
    echo "$CHANGED"
    echo '```'
  else
    echo "(clean)"
  fi
  echo
  echo "## Next"
  echo "- (review the above; not auto-injected — load deliberately)"
} > "$OUT.tmp"

# Hard ceiling: keep the file bounded for cheap reload (P0/P5).
tail -c 4000 "$OUT.tmp" > "$OUT"
rm -f "$OUT.tmp"

exit 0
