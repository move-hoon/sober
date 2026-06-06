> **[한국어 버전](README.ko.md)**

[![npm version](https://img.shields.io/npm/v/getsober.svg)](https://www.npmjs.com/package/getsober)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D18-blue.svg)](https://nodejs.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![GitHub stars](https://img.shields.io/github/stars/move-hoon/sober.svg?style=social)](https://github.com/move-hoon/sober)

# Sober

![Sober preview](https://github.com/user-attachments/assets/c4113ea9-06a5-43f8-bb5c-edc45ea82364)

**Stop your AI coding agent from wasting tokens and making blind guesses.**

---

## What is Sober?

Sober is not another AI. It is a small rules-and-tools package you install once on top of **Claude Code** or **Codex CLI** — the AI coding tools you already use.

After installing, you keep running `claude` or `codex` exactly as before. Sober quietly gives them better working habits:

- **Search before reading** — find the exact line instead of dumping whole files
- **Edit the smallest safe area** — patch only what needs to change
- **Verify with tests** — run the build before declaring success
- **Stop repeating failed guesses** — re-plan after a few failures
- **Report briefly** — show the result, not a wall of text

Don't like it? Run `sober uninstall` to remove Sober-owned links, hooks, and `~/.sober` while leaving your own config in place.

---

## Why use it?

AI coding agents are powerful, but they waste quota in predictable ways:

| Without Sober | With Sober |
|---|---|
| Reads entire files to find one line | Finds `file:line` first |
| Guesses where code lives | Uses search tools before opening files |
| Rewrites more than necessary | Makes the smallest safe patch |
| Says "done" without proof | Runs the right verification |
| Repeats failed attempts | Stops, explains, and re-plans |
| Produces long summaries | Reports result, changed files, and test output |

**The goal: spend model thinking on judgment, not on grep.**

---

## Core Architecture: The 5 Invariants

What survives even as models improve:
1. **Policy Contract:** The P0-P8 rules that cage the LLM to irreducible judgment.
2. **Deterministic Offload:** Code/tools handle search, transformation, and bulk output.
3. **Verification Gate & Isolation:** No state change without deterministic verification; parallel work stays in worktrees.
4. **Persistent Human-Reviewed Memory:** Local file-based memory (`HANDOFF.md`) instead of opaque DBs.
5. **Observation:** Every addition must be justified by measurement.

### L0-L6 Layered Architecture

This layered approach explains *why* we apply tools in a specific sequence:
*   **L0 Output:** Caveman (compressed output) + Context7 (prevents stale-API token waste)
*   **L1 Search:** ripgrep (`| head`) → Probe (structural) → mgrep (concept/semantic, last resort)
*   **L2 Edit:** ast-grep `--rewrite` (mechanical) + Serena `replace_symbol` (type-aware)
*   **L3 Symbol:** Serena (LSP)
*   **L3.5 Structure:** GitNexus / code-review-graph (hints, pre-change verification)
*   **L4 Verification & Isolation:** 1-shot verify → compile/test → budget caps → native worktrees
*   **L5 Memory:** `AGENTS.md` / `CLAUDE.md` (static rules) + `.serena/memories` (architecture facts) + `HANDOFF.md` (session state)
*   **L6 Observation:** Check `/context`, `/cost`, `/status` and KPI logs

### The Sober loop

```text
Ask one scoped task
  → locate exact lines
  → change with the smallest safe edit
  → verify with build/tests
  → write a short handoff
  → measure before adding anything
```

The loop lives in [`AGENTS.md`](AGENTS.md), the one rules file both runtimes read. Claude Code reads it through `CLAUDE.md`; Codex reads `AGENTS.md` directly.

---

## Quick Start

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) or [Codex CLI](https://github.com/openai/codex) must be installed first
- Node.js 18+

### Install

```bash
npm install -g getsober@latest
sober setup
```

### Verify

```bash
sober doctor
```

### Usage — applying to a new project

```bash
cd your-project
sober template .  # Generates AGENTS.md, HANDOFF.md, etc. in your project.
claude            # or: codex
```

### Where does it install?

To avoid confusion, files are installed in two distinct scopes:

1. **Global (Home Directory `~/`):** Created by `sober setup`.
   - `~/.sober`: The canonical source of truth for policies, hooks, and skills.
   - `~/.claude` & `~/.codex`: Configuration and rules injected by Sober.
2. **Local (Project Directory `./`):** Created by `sober template`.
   - `your-repo/AGENTS.md`: The project-specific policy spine.
   - `your-repo/HANDOFF.md`: The session continuity memory for this specific project.

Prompt with scoped tasks:

```text
Fix the login timeout bug. Find the right lines first, make the smallest safe change, and verify with tests.
```

That's it. Sober runs in the background. Your daily commands are still just `claude` or `codex`.

---

## Usage Guide

### Writing effective prompts

**Broad prompts without a stop condition waste the most quota.** Always include what "done" looks like.

The single most important habit: **tell the agent what to do, what not to touch, and how to verify.**

**Good prompt:**
```text
Change the payment retry timeout from 3s to 5s.
Keep behavior unchanged otherwise.
Verify with the existing payment tests.
```

**Bad prompt:**
```text
Clean up this repo.
```

### Skills — what they are and when to use them

Skills are not terminal commands. They are small instruction packs that shape how the agent works. You rarely need to name them directly — just describe the behavior you want.

| Skill | When it helps | Example prompt |
|---|---|---|
| `karpathy` | Every task | "Do only the requested change. Don't clean unrelated files." |
| `search-ladder` | Finding code | "Find the relevant `file:line` first. Don't read whole files." |
| `edit-deterministic` | Repeated changes | "Use a repeatable rewrite for all similar call sites." |
| `caveman` | Long responses | "Report only result, changed files, tests, and risks." |
| `observe` | Adding tools/rules | "Measure before and after. Keep it only if the metric improves." |
| `sober-review` | Before commit | "Run the sober-review checklist. Report issues only. Don't edit." |
| `structure-graph` | Large unfamiliar repos | "Map with structure-graph; before ANY edit, confirm the target exists with rg/Serena (one shot). Static graph misses runtime wiring." |

### When the agent gets stuck

Don't push harder — redirect.

1. **Shrink the task** into a smaller piece.
2. **Ask for a plan** before more edits: *"Write a 3-line plan before changing anything."*
3. **Re-check evidence** — the search results may be stale.
4. **3 failures = stop** — if the same idea failed 3 times, stop and re-plan from scratch.
5. **Analyze tool errors** — use `/analyze-failures` in Claude Code to see patterns.

### Session handoff

Long conversations get noisy. Before stopping:

```text
Summarize only: verified facts, remaining risks, and the next command to run.
```

Sober's handoff hook automatically writes a small `HANDOFF.md` with the current branch, last commit, and uncommitted changes when a session ends in a git project.

When you start a new session, ask the agent to read `HANDOFF.md` first to pick up where you left off.

### Review before commit

For non-trivial changes, run a read-only review:

```text
Run the sober-review checklist on this diff.
Report PASS or ISSUES only. Do not edit files.
```

This checks correctness, scope, complexity, style, verification coverage, and basic security — without touching any code.

### Measure before adding

Before adding any new tool, skill, or rule, run a before/after check. In Claude Code you can use Sober's `/measure` command; in Codex, use the same wording as a normal prompt:

```text
/measure baseline
# make exactly one change to your setup
/measure after
```

Key metrics to watch: files read per task, output tokens, peak context fill, retry rate. **If any metric gets worse, roll back.**

---

## Commands

```bash
sober install          # apply / refresh policy files globally
sober setup            # install + offer Context7 / search-edit toolkit
sober doctor           # check install, deps, hooks, optional tools
sober template [dir]   # add project-specific rules and HANDOFF.md
sober uninstall        # remove Sober symlinks and ~/.sober (clean exit)
```

---

## Optional Tools

Sober works without these. They make the agent's work cheaper when installed.

| Tool | Why it helps | Boundaries (What not to do) |
|---|---|---|
| `ripgrep` | Fast exact text search | Don't use for semantic/concept queries |
| `ast-grep` | Mechanical code-shape rewrites | Use for previewed rewrites; use Probe for structural repo search |
| Probe | Index-free structural repo search | Read-only; cannot rewrite code |
| Serena | Symbol-aware navigation and edits through LSP | Fails to map runtime DI/AOP wiring |
| Context7 / `ctx7` | Current library docs instead of stale API memory | Not for project-specific business logic |
| `mgrep` | Semantic search for concept queries (last resort) | Avoid for keyword/exact match (CoREB limit) |

```bash
sober setup       # offers to install these interactively
sober doctor      # shows what's present and what's missing
```

For Context7 directly:

```bash
npm install -g ctx7
ctx7 setup --cli --claude
ctx7 setup --cli --universal
```

For Codex MCP mode, enable Context7 explicitly:

```bash
codex mcp add context7 -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY
```

---

## Safety & Privacy

- **Additive install** — never overwrites your config; merges only Sober's hooks
- **Local at runtime** — no hosted Sober service; setup may download optional tools you choose
- **No API keys** — never asks for or touches your model credentials
- **Safety guardrails** — dangerous commands are caught by hooks (Claude) and Starlark rules (Codex)
- **You stay in control** — verification reminders are advisory-only; nothing blocks your `git commit`
- **No hidden memory** — session memory is a visible `HANDOFF.md` file you can read and edit
- **Secret redaction** — failure logs automatically mask API keys and tokens before writing

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Agent says a hook is missing | `sober doctor`, then `sober install` |
| Search tool not found | Keep working, or run `sober setup` to install it |
| Verification runs wrong stack | `~/.sober/scripts/verify.sh --path <subdir>` |
| Tool failures repeat | `/analyze-failures` in Claude Code, then re-plan |
| Output too long | Ask: *"Show only result, diff, and file:line"* |

---

<details>
<summary><strong>Architecture & Internals</strong> (click to expand)</summary>

### Project template output
```
your-repo/
├─ AGENTS.md          # project-specific header + shared Sober spine
├─ CLAUDE.md          # symlink to AGENTS.md (single source)
├─ HANDOFF.md         # bounded, reviewed session state
└─ sgconfig.yml       # optional, only with --with-sgconfig
```

### What gets installed

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

### Installed file tree

```text
~/.sober/AGENTS.md                    # shared policy source
~/.sober/commands/*.md                # Sober-owned Claude slash commands
~/.sober/rules/*.md                   # Sober-owned Claude rules
~/.sober/skills/<skill>/SKILL.md      # one copy of each skill
~/.sober/scripts/                     # local hook and verification scripts
~/.sober/codex-rules/*.rules          # installed copy of .sober/codex/rules

# Claude Code
~/.claude/CLAUDE.md                   # symlink to ~/.sober/AGENTS.md, or a managed @import block
~/.claude/AGENTS.md                   # symlink to ~/.sober/AGENTS.md, or a managed @import block
~/.claude/commands/<cmd>.md           → ~/.sober/commands/<cmd>.md
~/.claude/rules/<rule>.md             → ~/.sober/rules/<rule>.md
~/.claude/skills/<skill>              → ~/.sober/skills/<skill>
~/.claude/settings.json               # Sober hooks additively merged

# Codex CLI
~/.codex/AGENTS.md                    # contains/refreshes the Sober spine inline
~/.agents/skills/<skill>              → ~/.sober/skills/<skill>
~/.codex/hooks.json                   # Sober hooks additively merged
~/.codex/rules/*.rules                → ~/.sober/codex-rules/*.rules
```

### Runtime hooks

| Hook | What it does |
|---|---|
| `critical-action-check` | Blocks dangerous shell commands |
| `verify-gate` | Warns before commit/push if changes are unverified (advisory-only) |
| `handoff-write` | Writes `HANDOFF.md` on session stop |
| `session-start` | Loads safe env vars and shows budget reminder |
| `compact-suggest` | Suggests compaction when context gets long |
| `post-edit-format` | Auto-formats edited files if a formatter exists |
| `tool-failure-log` | Logs tool failures locally with secret redaction |

Codex runs the same hooks via `~/.codex/hooks.json`. The `sober-critical-actions.rules` file adds an extra Starlark check for dangerous commands.

</details>

---

## Code review and helper agents

Sober ships a **review checklist**, not a fixed reviewer pipeline.

Use a separate helper only when it pays for itself: reviewing non-trivial changes with fresh eyes, exploring large unfamiliar repos, or running truly independent tasks in parallel.

Avoid fixed multi-agent chains for everyday work. The checklist is in `.sober/skills/sober-review`; the actual helper can be Claude Code's native subagent, a Codex helper, or a reviewer you already trust.

---

## Develop

```bash
git clone https://github.com/move-hoon/sober.git
cd sober
npm test
npm pack --dry-run
```

Design decisions: [`docs/adr/`](docs/adr/) · Contributing: [`CONTRIBUTING.md`](CONTRIBUTING.md)

## License

MIT — see [LICENSE](LICENSE).
