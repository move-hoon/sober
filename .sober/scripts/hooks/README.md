> **[한국어 버전](README.ko.md)**

# Hooks — Automatic scripts

Hooks are small scripts that run automatically at certain moments to keep things safe and tidy. Claude Code loads them through `~/.claude/settings.json`; Codex loads the shared ones through `~/.codex/hooks.json`. You do not run these directly.

## What's here
| Hook | When it fires | What it does |
|---|---|---|
| `compact-suggest.sh` | After editing files | Reminds you to compact the chat if it's getting too long. |
| `critical-action-check.sh` | Before running a command | Pauses dangerous commands (like `rm -rf`) so you can review them. |
| `handoff-write.sh` | When you close the AI | Writes a short summary of what you did to a file. |
| `post-edit-format.sh` | After editing files | Automatically formats the code you just changed. |
| `session-start.sh` | When you start the AI | Loads safe settings without leaking your passwords. |
| `tool-failure-log.sh` | When a tool fails | Logs the error so you can fix it instead of looping forever. |
| `verify-gate.sh` | Before running a command | Warns you if you try to commit code without testing it first. |
