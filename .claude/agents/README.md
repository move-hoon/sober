> **[한국어 버전](README.ko.md)**

# Agents — helper roles

This folder is empty on purpose. Sober does not install a fixed cast of helper agents; it keeps the shared rules and checklists, then lets Claude Code or Codex run helpers in their own native way when that is useful.

## What's here
| File / item | What it does |
|---|---|
| `README.md` / `README.ko.md` | Explains why this managed folder stays empty by default. |

## When to use a helper
Use a separate helper when the work really benefits from a separate view:

- several independent jobs can run at the same time;
- a large unfamiliar codebase needs exploration;
- a read-only review should catch things the author may have missed.

For code review, Sober provides the checklist in `skills/sober-review`. Ask your runtime to apply that checklist in a separate read-only helper if it supports one. Personal agents belong in the runtime's user-level folder, not in this Sober-managed folder:

- Claude Code: `~/.claude/agents/`
- Codex: `~/.codex/agents/`

Sober should add a project-managed agent only after measuring that it helps and updating the installer on purpose.
