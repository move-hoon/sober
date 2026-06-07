# Sober

![Sober preview](https://github.com/user-attachments/assets/c4113ea9-06a5-43f8-bb5c-edc45ea82364)

[![npm version](https://img.shields.io/npm/v/getsober.svg)](https://www.npmjs.com/package/getsober)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D18-blue.svg)](https://nodejs.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![GitHub stars](https://img.shields.io/github/stars/move-hoon/sober.svg?style=social)](https://github.com/move-hoon/sober)

---

<div align="center">

**Language / 언어**

[**English**](README.md) | [한국어](README.ko.md)

</div>

---

**Keep your AI coding agent calm, constrained, and evidence-driven.**

Sober is a local control harness for Claude Code and Codex CLI. It keeps agents from over-reading, over-editing, and claiming “done” without proof by making them follow a simple working loop:

```text
locate facts → read only what matters → make the smallest safe change → verify → leave a handoff
```

At the center is one shared `AGENTS.md`: the workflow contract both runtimes follow.

Nothing is overwritten. Everything is additive. Uninstall removes only Sober-owned files.

```bash
npm install -g getsober@latest
sober setup
```

Use Sober as the default control layer, then add your own commands, subagents, MCP tools, and project-specific rules on top.

---

## Why Sober?

AI coding agents are powerful, but their default behavior is often too eager.

| Without Sober                      | With Sober                                     |
| ---------------------------------- | ---------------------------------------------- |
| Reads entire files to find one line | Finds the exact `file:line` first              |
| Guesses where code lives           | Checks candidates with deterministic tools     |
| Rewrites more than the task asked for | Makes the smallest safe patch               |
| Formats or cleans unrelated code   | Leaves unrelated files alone                   |
| Says "done" without proof          | Runs the closest build, test, or verification  |
| Repeats the same failed idea       | Stops after repeated failures and re-plans     |
| Produces long confident summaries  | Reports result, changed files, tests, and risks|
| Loses context between sessions     | Leaves a bounded `HANDOFF.md`                  |

**The goal: keep the model for judgment, while the workflow stays factual, small, and verifiable.**

---

## What is Sober?

Sober is not another AI agent. It is not a hosted service, a prompt pack, or a token optimizer.

Sober is a local control harness for the AI coding tools you already use: **Claude Code** and **Codex CLI**.

It installs a shared `AGENTS.md`, skills, and hooks that keep your existing agents inside a disciplined workflow:

- **Fact before context** — locate the exact `file:line` before opening broad files.
- **Evidence before edits** — verify the target with deterministic tools before changing code.
- **Small patches only** — touch only what the task requires.
- **Proof before "done"** — run the closest build, test, or verification step.
- **Stop after repeated failure** — do not burn more context repeating the same failed guess.
- **Brief reports only** — report result, changed files, verification, and risks.
- **Visible handoff** — preserve session state in a local `HANDOFF.md`.

After installing, you keep running `claude` or `codex` exactly as before.

Don't like it? Run `sober uninstall` to remove Sober-owned links, hooks, and `~/.sober` while leaving your own config in place.

---

## How to think about Sober

Sober sits at a different layer than models, MCP tools, custom commands, or subagents.

| Layer                   | What it does                    | How Sober relates                                                 |
| ----------------------- | ------------------------------- | ----------------------------------------------------------------- |
| Claude Code / Codex CLI | Runs the AI coding agent        | Sober does not replace them; it keeps them inside a verifiable workflow |
| MCP tools               | Extend what the agent can access| Sober shapes how and when tools should be used                    |
| Custom commands         | Add task-specific workflows     | Sober is the default behavior layer those workflows start from   |
| Subagents               | Divide or delegate work         | Sober shapes how each agent approaches the work                   |
| Prompt packs            | Instructions you paste into chat| Sober is structure you install into local config and project files|

If you need an analogy: Sober is a **control harness and workflow contract** for AI coding agents. It does not create a new agent; it keeps your existing Claude Code and Codex CLI inside a calmer loop: find facts, patch small, verify, and hand off.


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

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) or [Codex CLI](https://github.com/openai/codex) must be installed first.
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

### Apply Sober to a project

```bash
cd your-project
sober template .  # Generates AGENTS.md, HANDOFF.md, etc. in your project.
claude            # or: codex
```

Prompt with scoped tasks:

```text
Fix the login timeout bug.
Find the right lines first, make the smallest safe change, and verify with tests.
```

That's it. Your daily commands are still just `claude` or `codex`.

### Where does it install?

Sober uses two distinct scopes:

1. **Global home scope (`~/`)** — created by `sober setup`
   - `~/.sober`: canonical source of truth for policies, hooks, and skills.
   - `~/.claude` and `~/.codex`: configuration and rules injected by Sober.

2. **Local project scope (`./`)** — created by `sober template`
   - `your-repo/AGENTS.md`: project-specific policy spine.
   - `your-repo/HANDOFF.md`: session continuity memory for this project.

---

## Usage Guide

### Writing effective prompts

Broad prompts without a stop condition waste the most quota. Always include what "done" looks like.

The single most important habit: **tell the agent what to do, what not to touch, and how to verify.**

Good prompt:

```text
Change the payment retry timeout from 3s to 5s.
Keep behavior unchanged otherwise.
Verify with the existing payment tests.
```

Bad prompt:

```text
Clean up this repo.
```

### Skills — what they are and when to use them

Skills are not terminal commands. They are small instruction packs that shape how the agent works.

You rarely need to name them directly. Describe the behavior you want.

| Skill                | When it helps                                                              | Example prompt                                                                                                              |
| -------------------- | -------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `karpathy`           | Every task                                                                 | "Do only the requested change. Don't clean unrelated files."                                                                |
| `search-ladder`      | Finding code                                                               | "Find the relevant `file:line` first. Don't read whole files."                                                              |
| `edit-deterministic` | Repeated changes                                                           | "Use a repeatable rewrite for all similar call sites."                                                                      |
| `caveman`            | Long responses                                                             | "Report only result, changed files, tests, and risks."                                                                      |
| `observe`            | Adding tools/rules                                                         | "Measure before and after. Keep it only if the metric improves."                                                            |
| `sober-review`       | Before commit                                                              | "Run the sober-review checklist. Report issues only. Don't edit."                                                           |
| `structure-graph`    | Large or unfamiliar repos with unclear flows, dependencies, or blast radius | "Map with GitNexus CLI for structure hints; before reading deeply or editing, verify the candidate with rg/Probe."          |

### When the agent gets stuck

Don't push harder — redirect.

1. **Shrink the task** into a smaller piece.
2. **Ask for a plan** before more edits: "Write a 3-line plan before changing anything."
3. **Re-check evidence** — the search results may be stale.
4. **3 failures = stop** — if the same idea failed three times, stop and re-plan from scratch.
5. **Analyze tool errors** — in Claude Code, use `/analyze-failures`. In Codex CLI, ask it to run `~/.sober/scripts/analyze-failures.sh`, read only the script output, summarize repeated failure patterns, and propose the next smallest plan.

### Session handoff

Long conversations get noisy. Before stopping, ask for a bounded handoff:

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

This checks correctness, scope, complexity, style, verification coverage, and basic security — without touching code.

### Measure before adding

Before adding any new tool, skill, or rule, run a before/after check.

In Claude Code you can use Sober's `/measure` command. In Codex, use the same wording as a normal prompt:

```text
/measure baseline
# make exactly one change to your setup
/measure after
```

Key metrics to watch:

- Files read per task
- Output tokens
- Peak context fill
- Retry rate

If any metric gets worse, roll back.

---

## Commands

```bash
sober install          # apply / refresh policy files globally
sober setup            # install policy, then interactively offer Context7 and the core search/edit toolkit
sober doctor           # check install, deps, hooks, and optional tool status
sober template [dir]   # add project-specific rules and HANDOFF.md
sober uninstall        # remove Sober symlinks and ~/.sober
```

---

## Optional Tools

Sober works without these tools. Some of them reduce files read, output volume, or retry loops for specific tasks.

`sober setup` interactively offers the core search/edit toolkit — `ripgrep`, `ast-grep`, `Probe` — plus Context7 setup.

Conditional tools such as `GitNexus`, `Serena`, and `mgrep` are reported by `sober doctor` and should be added manually only when they pay for themselves.

### Core optional toolkit

These tools pay off in most projects. They make Sober's default loop — search, minimal edit, verify, brief report — cheaper and more reliable.

| Tool | Sober role | Trigger |
|---|---|---|
| `ripgrep` | Locate exact text fast | Known symbol, keyword, or regex |
| `ast-grep` | Apply mechanical rewrites | Repeated code-shape changes |
| Probe | Find structural code candidates | Definitions, call sites, code patterns |

### Conditional tools

Add these only when the task calls for them. They are not part of the default install path; `sober doctor` reports their status and install hints.

| Tool | Sober role | Trigger |
|---|---|---|
| Serena | Symbol-aware navigation and edits | Type-aware single-symbol changes |
| Context7 / `ctx7` | Current external docs | Library API uncertainty |
| `gitnexus` | Structure hints for large repos | Unclear flow, dependency, or blast radius |
| `mgrep` | Last-resort concept search | Exact token name is unknown |

Sober does not treat optional tools as always-on power-ups. Tools are selected by trigger, verified by evidence, and rolled back if they increase read volume, output volume, or retry rate.

**GitNexus note:** Sober treats GitNexus as a structure-hint generator, not a source of truth. Use `gitnexus analyze --skip-agents-md --skip-skills --skip-embeddings`, then verify candidates with `rg` or Probe before deep reading.

```bash
sober setup       # installs policy, then interactively offers the core toolkit and Context7 setup
sober doctor      # shows current status and install hints for conditional tools
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

- **Additive install** — never overwrites your config; merges only Sober-owned hooks and rules.
- **Local at runtime** — no hosted Sober service; setup may download optional tools you choose.
- **No API keys** — never asks for or touches your model credentials.
- **Safety guardrails** — dangerous commands are caught by hooks for Claude and Starlark rules for Codex.
- **Advisory verification** — verification reminders do not block your `git commit`.
- **No hidden memory** — session memory is a visible `HANDOFF.md` file you can read and edit.
- **Secret redaction** — failure logs mask API keys and tokens before writing.

---

## Troubleshooting

| Symptom                       | Fix                                                |
| ----------------------------- | -------------------------------------------------- |
| Agent says a hook is missing  | `sober doctor`, then `sober install`               |
| Search tool not found         | Keep working, or run `sober setup` to install it   |
| Verification runs wrong stack | `~/.sober/scripts/verify.sh --path <subdir>`       |
| Tool failures repeat          | `/analyze-failures` (Claude) or run script (Codex), then re-plan |
| Output too long               | Ask: "Show only result, diff, and file:line"       |

---



## Core Architecture: The 5 Invariants

What survives even as models improve:

1. **Policy Contract:** The P0-P8 rules that cage the LLM to irreducible judgment.
2. **Deterministic Offload:** Code/tools handle search, transformation, and bulk output.
3. **Verification Gate & Isolation:** No state change without deterministic verification; parallel work stays in worktrees.
4. **Persistent Human-Reviewed Memory:** Local file-based memory (`HANDOFF.md`) instead of opaque databases.
5. **Observation:** Every addition must be justified by measurement.

### L0-L6 Layered Architecture

This layered approach explains *why* tools are applied in a specific sequence:

- **L0 Output:** Caveman compressed output + Context7 for current external docs.
- **L1 Search:** `ripgrep` (`| head`) → Probe for structural search → `mgrep` for concept/semantic search as a last resort.
- **L2 Edit:** `ast-grep --rewrite` for mechanical edits + Serena `replace_symbol` for type-aware edits.
- **L3 Symbol:** Serena for LSP-backed symbol navigation.
- **L3.5 Structure:** GitNexus CLI for conditional structure hints; verify candidates with `rg` or Probe before deep reading. MCP stays disabled by default.
- **L4 Verification & Isolation:** One-shot verify → compile/test → budget caps → native worktrees.
- **L5 Memory:** `AGENTS.md` / `CLAUDE.md` for static rules, `.serena/memories` for architecture facts, and `HANDOFF.md` for session state.
- **L6 Observation:** Check `/context`, `/cost`, `/status`, and KPI logs.

### Project template output

```text
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
~/.claude/CLAUDE.md                   # symlink to ~/.sober/AGENTS.md, or managed @import block
~/.claude/AGENTS.md                   # symlink to ~/.sober/AGENTS.md, or managed @import block
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

| Hook                    | What it does                                                       |
| ----------------------- | ------------------------------------------------------------------ |
| `critical-action-check` | Blocks dangerous shell commands                                    |
| `verify-gate`           | Warns before commit/push if changes are unverified; advisory-only  |
| `handoff-write`         | Writes `HANDOFF.md` on session stop                                |
| `session-start`         | Loads safe env vars and shows budget reminder                      |
| `compact-suggest`       | Suggests compaction when context gets long                         |
| `post-edit-format`      | Auto-formats edited files if a formatter exists                    |
| `tool-failure-log`      | Logs tool failures locally with secret redaction                   |

Codex runs the same hooks via `~/.codex/hooks.json`. The `sober-critical-actions.rules` file adds an extra Starlark check for dangerous commands.


---

## Code review and helper agents

Sober ships a review checklist, not a fixed reviewer pipeline.

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

- Design decisions: [`docs/adr/`](docs/adr/) 
- Contributing: [`CONTRIBUTING.md`](CONTRIBUTING.md)

## License

MIT — see [LICENSE](LICENSE).
