# Contributing to Sober

Thank you for considering a contribution to Sober. Whether it's a bug report, a new skill or hook, or a documentation fix — all contributions are welcome regardless of skill level.

> Sober is a **policy-spine harness** for Claude Code and Codex CLI. Every design decision keeps the LLM caged to judgment and offloads the rest to deterministic tools.

## Table of Contents

- [Ways to Contribute](#ways-to-contribute)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Design Principles](#design-principles)
- [What We Look For](#what-we-look-for)
- [Submitting Changes](#submitting-changes)
- [Code Guidelines](#code-guidelines)
- [Documentation](#documentation)

## Ways to Contribute

- **Report bugs** — something broken during install or in a Claude Code / Codex session
- **Suggest features** — new skills, hooks, or rules that save quota
- **Improve docs** — fix typos, clarify instructions, add examples
- **Share data** — if you've measured impact (Claude Code `/measure`, or your runtime's cost/context view), your findings help everyone

## Getting Started

### Prerequisites

- Node.js ≥ 18
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and/or Codex CLI
- (Optional) [mgrep](https://www.npmjs.com/package/@mixedbread/mgrep) — semantic search; reported to cut CLI output tokens (~50%, hypothesis until you measure your own)

### Setup

```bash
git clone https://github.com/move-hoon/sober.git
cd sober
bash install.sh
```

Verify your setup:

```bash
sober doctor
```

To test changes during development, re-run `bash install.sh` after editing — it deploys to the single home `~/.sober` and symlinks the runtimes into it (`~/.claude`, `~/.codex`, `~/.agents/skills`).

## Project Structure

Sober is not a typical npm library. The core product is **policy + workflow configuration** — markdown files, shell scripts, and a thin CLI.

> For the complete file tree, see [README.md — Project Structure](README.md#-project-structure).

| Directory | Purpose |
|-----------|---------|
| `.claude/skills/` | On-demand skills (shared by Claude Code + Codex) — the main surface |
| `.claude/rules/` | Claude-specific soft rules (prompts) |
| `.claude/commands/` | The two helper commands (`/measure`, `/analyze-failures`) |
| `.claude/agents/` | Reserved — Sober bundles **no** agents (README only) |
| `codex/` | Codex-specific parity files (`hooks.json`, Starlark execution policies) |
| `scripts/hooks/` | Local hooks (zero API cost, shared implementation) |
| `scripts/runtime/` | Runtime auto-detection and adapters |
| `bin/sober.js` | CLI entry point (self-contained) |
| `install.sh` | One-click installer |

## Design Principles

1. **Quota-first** — Every feature must justify its cost. If it burns more quota than it saves, it doesn't belong.
2. **Fewer turns > cheaper model** — Sonnet in 1 turn can cost less than Haiku in 3. Quota impact depends on model choice, turn count, and output size — not model alone.
3. **Empirical, not theoretical** — Anthropic doesn't publish quota formulas. When documenting quota impact, back it with a before/after measurement (Claude Code `/measure`, or your runtime's cost/context view). Any external number is a hypothesis until you measure it locally. Ideas and suggestions don't need data — just flag them as untested.

## What We Look For

**Good fits:**
- New skills, hooks, or rules that reduce quota waste
- Improvements to failure recovery (fewer wasted turns)
- Output control enhancements (shorter agent responses, better filtering)
- Bug fixes in `install.sh` or `bin/sober.js`
- Documentation improvements

**We don't accept:**
- Features unrelated to quota efficiency or Claude Code / Codex workflows
- Changes that increase default output verbosity
- Stylistic refactors with no functional impact
- External runtime dependencies in `bin/sober.js`

## Submitting Changes

### Bug Reports

[Open an issue](https://github.com/move-hoon/sober/issues/new) with:
- What you expected vs. what happened
- OS, Node version, Claude Code / Codex version
- Output from `sober doctor`
- Steps to reproduce

### Feature Requests

[Open an issue](https://github.com/move-hoon/sober/issues/new) describing:
- The quota or workflow problem you're solving
- Why existing commands don't cover it
- Measurement data (if available) — before/after deltas (`/measure` or your runtime's cost/context view)

### Pull Requests

1. Fork the repo and create a branch: `git checkout -b feat/your-feature`
2. Make your changes
3. Test with `sober doctor` and a real Claude Code or Codex session
4. Ensure both `README.md` and `README.ko.md` are updated if your change affects docs
5. Submit a PR with a clear description of **what changed** and **why**

We aim to review PRs within 7 days. For significant changes, open an issue first to align on direction.

## Code Guidelines

- Follow the style of existing code — consistency matters more than rules
- JS (`bin/sober.js`): no external runtime dependencies — keep it self-contained
- Commit messages: use [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`)

## Documentation

Sober maintains bilingual documentation:

| File | Language |
|------|----------|
| `README.md` | English |
| `README.ko.md` | Korean |
| `docs/USER-MANUAL.md` | English |
| `docs/USER-MANUAL.ko.md` | Korean |

If your change affects user-facing docs, please update **both language versions** or note in your PR that a translation is needed.

---

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
