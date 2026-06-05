> **[한국어 버전](README.ko.md)**

[![npm version](https://img.shields.io/npm/v/getsober.svg)](https://www.npmjs.com/package/getsober)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D18-blue.svg)](https://nodejs.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![GitHub stars](https://img.shields.io/github/stars/move-hoon/sober.svg?style=social)](https://github.com/move-hoon/sober)


# Sober

![Sober preview](https://github.com/user-attachments/assets/c4113ea9-06a5-43f8-bb5c-edc45ea82364)

**A local behavior harness that makes Claude Code and Codex CLI read less, guess less, and verify more.**

Sober is a small, local harness to make AI coding tools like Claude Code and Codex CLI run more consistently and efficiently. It installs one rules file, a few focused skills, and lightweight safety hooks so your agent reads only what it needs, locates target lines using actual search tools, makes pinpoint edits, verifies changes via tests, and stops looping on failed guesses.

It is not a new agent runtime. It does not run a service. It does not ask for API keys. Once installed, simply ask Claude Code or Codex CLI for tasks, and both runtimes will align behind the same working contract.

### Before & After

- **Before Sober**: Agents read entire files blindly, guess code locations, and spend quota on verbose explanations.
- **After Sober**: Agents locate target lines with tools, make minimal edits, verify changes via tests, and report briefly.

Sober drastically reduces context byte inflow per task by enforcing target-line reading, pinpoint tool searches, and diff-only outputs instead of full-file dumps. For design decisions and constraints, see [`docs/adr/`](docs/adr/).

> 💡 **How to use**: After installing Sober, just request tasks via `claude` or `codex` command as usual. Sober does not run a separate runtime; it simply links rules, skills, and hooks into each CLI's configuration.

---

## Quick start

```bash
npm install -g getsober@latest
sober install
sober doctor
```

That gives you:

- one source of truth in `~/.sober`
- shared rules for Claude Code and Codex CLI
- Sober skills linked into each runtime
- Claude Code and Codex hooks/rules for safety, handoff, formatting, compact reminders, and failure logs

Sober does not intercept OS-level processes; it simply links rules, skills, and hooks into the CLI's configuration endpoints.

Common commands:

```bash
sober install          # apply / refresh Sober's policy files globally
sober setup            # install deps + optional Context7 / search-edit toolkit
sober doctor           # check install, deps, hooks, and optional tools
sober template [dir]   # bootstrap a specific project with local rules and HANDOFF.md memory
sober uninstall        # remove Sober symlinks and ~/.sober
```

First request example (to guide the agent's behavior correctly):

> "Fix this bug. Locate the relevant files first, make the minimal required edits, and verify with tests."

Install from source if you want to audit every line first:

```bash
git clone https://github.com/move-hoon/sober.git
cd sober
bash install.sh
```

---

## What Sober Solves

Most quota waste is boring and predictable.

| What usually happens | What Sober teaches the agent to do |
|---|---|
| Read whole files to find one line | Locate exact `file:line` matches first |
| Guess where code lives | Search with `ripgrep`, `ast-grep`, Probe, or Serena |
| Hand-rewrite mechanical edits | Use repeatable command-line transforms |
| Change code from stale navigation | Re-check the target, then run compile/tests |
| Retry the same failed idea | Stop after a few misses and re-plan |
| Produce long explanations and full-file dumps | Return diffs, paths, and the decision that matters |
| Add tools because they sound useful | Measure before/after; remove what does not pay |

The rule of thumb: **spend model thinking on judgment, not grep.**

---

## The Sober loop

```text
Ask one scoped task
  → locate exact lines
  → change with the smallest safe edit
  → verify with build/tests
  → write a short handoff
  → measure before adding anything
```

The loop lives in [`AGENTS.md`](AGENTS.md), the one rules file both runtimes read. Claude Code reads it through `CLAUDE.md`; Codex reads `AGENTS.md` directly.

You do not need to memorize internal policy codes. In plain language, Sober asks the agent to:

1. read only what it needs
2. search with real tools **(`search-ladder` skill)**
3. use tools for mechanical edits **(`edit-deterministic` skill)**
4. verify before changing state **(`verify-gate` hook)**
5. stop and re-plan after repeated failure
6. keep memory human-reviewed and file-based **(`HANDOFF.md`)**
7. isolate risk behind git
8. measure every harness addition **(`observe` skill)**
9. keep output compact **(`caveman` skill)**

The longer reasoning behind these choices is recorded in [`docs/adr/`](docs/adr/).

---

## What gets installed

Sober sets `~/.sober` as the shared configuration source, allowing both Claude Code and Codex CLI to read the same rules and skills. It safely links rules, skills, and hooks into each CLI's native configuration format.

```text
┌──────────────────────────────────────────────────────────────┐
│                         Sober                                │
│                    shared home: ~/.sober                     │
│                                                              │
│   ┌──────────────┬──────────────┬────────────────────────┐   │
│   │   AGENTS.md  │   skills/    │        scripts/        │   │
│   │ shared rules │ tool habits  │ safety + handoff hooks │   │
│   └──────────────┴──────────────┴────────────────────────┘   │
│             ↓              ↓                  ↓              │
│        Claude Code      Codex CLI        project template    │
│        ~/.claude        ~/.codex         AGENTS/HANDOFF      │
│             ↓              ↓                  ↓              │
│      merged settings   hooks + rules     local overrides     │
└──────────────────────────────────────────────────────────────┘
```

### File Tree

```text
~/.sober/AGENTS.md                 # shared rules source
~/.sober/skills/<skill>/SKILL.md   # one copy of each skill

# For Claude Code Users
~/.claude/CLAUDE.md  -> ~/.sober/AGENTS.md
~/.claude/AGENTS.md  -> ~/.sober/AGENTS.md
~/.claude/skills/*   -> ~/.sober/skills/*
~/.claude/settings.json            # Sober hooks are additively merged here

# For Codex CLI Users
~/.codex/AGENTS.md   -> ~/.sober/AGENTS.md
~/.agents/skills/*   -> ~/.sober/skills/*
~/.codex/hooks.json                 # Sober hooks are additively merged here
~/.codex/rules/sober-critical-actions.rules -> ~/.sober/codex-rules/sober-critical-actions.rules
```

Project-level `AGENTS.md`, `.claude/`, or `.codex/` files can still override the global setup.

---

## Skills

| Skill | Job |
|---|---|
| `karpathy` | Stay scoped: no invented requirements, no over-building, no unrelated edits, match local style |
| `caveman` | Keep answers short: result, diff, `file:line`, no ceremony |
| `search-ladder` | Find code in the cheapest reliable order |
| `edit-deterministic` | Route mechanical edits to tools instead of manual rewrites |
| `observe` | Measure context, cost, retries, and failures before adding tools |
| `structure-graph` | Use repo graphs only as hints for large-codebase flow tracing |
| `sober-review` | A portable code-review checklist; it reports issues and never edits |

---

## Optional tools

Sober works without these. They make the loop cheaper when installed.

| Tool | Why it helps |
|---|---|
| `ripgrep` | Fast exact text search |
| `ast-grep` | Structural code search and mechanical rewrites |
| Probe | Index-free structural repo search |
| Serena | Symbol-aware navigation and edits through LSP |
| Context7 / `ctx7` | Current library docs instead of stale API memory |
| `mgrep` | Semantic search for concept queries, last resort |

Run:

```bash
sober doctor
sober setup
```

For Context7 directly:

```bash
npm install -g ctx7
ctx7 setup --cli --claude
```

`doctor` shows what is present. `setup` can install missing required dependencies and offer optional integrations.

---

## Code review and helper agents

Sober ships the **review checklist**, not a fixed reviewer pipeline.

Use a separate helper when it pays for itself:

- reviewing a non-trivial change with fresh eyes
- exploring a large unfamiliar repository
- running several truly independent tasks in parallel

Avoid fixed multi-agent chains for everyday work. They often spend more quota than they save. The checklist is in `skills/sober-review`; the actual helper can be Claude Code's native subagent, a Codex helper, or a reviewer you already trust.

---

## Safety and privacy

- **Additive Installation**: Sober never overwrites your config. It safely merges its hooks into `settings.json` and `hooks.json`. Your environment variables, permissions, and existing tools are preserved.
- **Purely Local**: Sober is local configuration and bash scripts, not a hosted service.
- **No API Keys**: Sober never asks for or touches your model API keys.
- **Safety Guardrails**: Dangerous shell commands are detected and blocked prior to execution by Claude Hooks and Codex Starlark Rules.
- **User in Control**: Verification reminders (like testing before committing) are advisory-only and do not block your `git commit` or `push` commands. You retain final control over what gets executed.
- **No Hidden Memory**: Session memory is a small, visible `HANDOFF.md` file for humans to review. No automatic hidden memory bloating your context.
- **Local Failure Logs & Redaction**: Tool-failure logs are stored locally and automatically redact common secret patterns before writing.

---

## Learn the workflow

- Day-to-day guide: [`docs/USER-MANUAL.md`](docs/USER-MANUAL.md)
- Design decisions: [`docs/adr/`](docs/adr/)
- Contributing: [`CONTRIBUTING.md`](CONTRIBUTING.md)

---

## Develop

```bash
git clone https://github.com/move-hoon/sober.git
cd sober
npm test
npm pack --dry-run
```

## License

MIT — see [LICENSE](LICENSE).
