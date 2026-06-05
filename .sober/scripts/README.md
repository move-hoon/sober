> **[한국어 버전](README.ko.md)**

# Scripts — Local command-line scripts

These are small scripts that do repeatable work locally on your machine. We use these to save AI budget, letting plain command-line tools do the boring work instead of having the AI read and think about it.

## What's here
| File / Directory | What it does |
|---|---|
| `verify.sh` | Figures out your project type and runs the right build or test commands. |
| `analyze-failures.sh` | Summarizes the tool failure log so you can see what went wrong. |
| `hooks/` | Tiny scripts used by Claude Code hooks and most Codex hooks. |
| `codex-hooks/` | Small adapters for Codex events that need a slightly different input shape. |
| `runtime/` | Helper scripts that teach `verify.sh` how to build different languages. |
