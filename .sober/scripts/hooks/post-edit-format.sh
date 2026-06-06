#!/bin/bash
# post-edit-format.sh - PostToolUse Hook
# Auto-formatting after file edits (0 tokens)
# Hardened Hook

set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
[ -z "${INPUT:-}" ] && exit 0
printf '%s\n' "$INPUT" | jq -e . >/dev/null 2>&1 || exit 0

FILE_PATH=$(printf '%s\n' "$INPUT" | jq -r '.tool_input.file_path // .tool_response.filePath // empty')

# Skip if file path is missing or file does not exist
[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Select formatter by extension
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.md)
    if command -v prettier &>/dev/null; then
      prettier --write "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.py)
    if command -v black &>/dev/null; then
      black --quiet "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.go)
    if command -v gofmt &>/dev/null; then
      gofmt -w "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.rs)
    if command -v rustfmt &>/dev/null; then
      rustfmt "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
esac

exit 0
