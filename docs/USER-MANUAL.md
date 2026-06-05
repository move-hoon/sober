# Sober — User Manual

Sober helps Claude Code and Codex CLI work in the same way. The goal is to find exact lines first, make small edits, verify early, and keep reports short. This guide explains how developers can work with the agent after running `sober install`.

## 0. 3-Minute Quick Start

To start using Sober right away:

1. Perform a quick check of the installation:
   ```bash
   sober doctor
   ```
2. Navigate to your project folder and run Claude:
   ```bash
   cd your-project
   claude
   ```
   Or run Codex:
   ```bash
   cd your-project
   codex
   ```
3. Request tasks naturally, prompting in a way that aligns with Sober's habits:
   ```text
   Fix this bug. Locate the relevant lines first, make the minimum changes required, and verify with tests.
   ```

> [!NOTE]
> Sober works out of the box with just a global install. You only need to run `sober template .` if you want project-specific rules or a shared `HANDOFF.md` memory file.

## 1. Check the install

```bash
sober doctor
```

Read the output as a map:

- **Required deps (Required Deps)**: Core tools that Sober needs to run, such as `jq`.
- **Optional tools (Optional Tools)**: Tools that make the workflow cheaper, such as `ast-grep`, Probe, Serena, Context7, and `mgrep`.
- **Runtime hooks (Hooks)**: Runtime automation scripts (Claude hooks in `~/.claude/settings.json`, Codex hooks in `~/.codex/hooks.json`, Sober scripts in `~/.sober/scripts`).

> [!NOTE]
> If any optional tool is missing, Sober still works fine. Install optional tools only when you need them to help with your work.

## 2. Add Sober to a project (Optional)

Run this command only if you want project-specific rules or a `HANDOFF.md` file:

```bash
sober template .
# or, if you want an ast-grep starter config:
sober template . --with-sgconfig
```

> [!NOTE]
> The `sober template` command never modifies or overwrites your existing source code; it only adds rule files safely.  
> These files are automatically read by the agent (Claude Code / Codex CLI) from the project root at session startup. There is no need to manually copy and paste the rules into your chat.

This creates:

| File | Purpose |
|---|---|
| `AGENTS.md` | Project rules and Sober common rules |
| `CLAUDE.md` | Link to let Claude Code read `AGENTS.md` |
| `HANDOFF.md` | Work notes for reference in the next session |
| `sgconfig.yml` | ast-grep starter config (Optional) |

> [!IMPORTANT]
> Edit only the project-specific section of `AGENTS.md`. Keep the shared Sober section short and intact.

## 3. Start a task

It is best to request one clear task at a time from the AI agent:

```text
Change the payment retry timeout from 3s to 5s.
Keep behavior unchanged otherwise.
Verify with the existing payment tests.
```

Good task prompts include:
- the target result
- what must not change
- how to verify completion
- any files, modules, or APIs already known

> [!WARNING]
> Avoid broad prompts like “clean this repo” unless you also define the stop condition.

## 4. Locate before reading

Sober's core habit is to find the relevant lines before opening files.

Preferred search order:
1. `ripgrep` for exact text
2. `ast-grep` or Probe for code shape
3. Serena for symbol references
4. semantic search only for concept questions

Good evidence looks like this:
```text
src/payments/retry.ts:42
src/payments/retry.test.ts:88
```

> [!TIP]
> A wall of pasted files is inefficient. Ask the agent to return `file:line` plus only the nearby lines.

## 5. Edit with the smallest safe move

Choose the smallest editing method that fits the change:

| Change shape | Preferred move |
|---|---|
| One local logic change | normal patch |
| Repeated mechanical change | `ast-grep --rewrite` preview, then apply |
| Rename/edit a typed function, class, or variable | Serena symbol-aware edit |
| Large uncertain refactor | plan first, then split into small verified steps |

Avoid letting the agent rewrite whole files just to make a small mechanical change.

## 6. Verify before calling it done

Use the Sober verification script before calling a task complete:

```bash
~/.sober/scripts/verify.sh
```

For monorepos:
```bash
~/.sober/scripts/verify.sh --path packages/api
```

The verifier detects common stacks such as Node, JVM, Rust, Go, Python, and a generic `make` fallback. If automatic detection does not work, directly specify the smallest test command to verify the change.

> [!TIP]
> If your tests require environment variables, make sure your `.env` or `.env.local` file is properly configured in the project root before running verification.

> [!IMPORTANT]
> It is best to accept a task as done only after verifying the actual test or build outputs.

## 7. When the agent gets stuck

Do not keep retrying the same idea.

1. Shrink the task.
2. Ask for a short plan before making more edits.
3. Re-check the search evidence.
4. If the same hypothesis failed three times, stop and re-plan.
5. Use `/analyze-failures` in Claude Code if tool errors repeat.

The goal is not more effort. The goal is a better next move.

## 8. Summarizing long conversations (Compaction) and session handoff

If a conversation gets too long and noisy, ask the agent to summarize (`compact`). Keep only the decided facts and drop dead ends.

The Sober handoff hook writes a bounded `.claude/HANDOFF.md` on session stop when the runtime provides a project directory. It includes the active branch, last commit, and a summary of uncommitted changes.

> [!TIP]
> Useful habit before stopping:
> `"Summarize only verified facts, remaining risks, and the next command to run."`
> When you resume a session, ask the agent to read the `HANDOFF.md` file first. It is not a hidden file automatically loaded into the agent's memory.

## 9. Measure before adding tools

Before adding a tool, skill, hook, or rule, run a small before/after check on the same task.

In Claude Code:
```text
/measure baseline
# make exactly one harness change
/measure after
```

Track:
- **Files read per task (Files read/task)**: lower means narrower context
- **Output tokens (Output tokens)**: lower means less quota burned in answers
- **Peak context fill (Peak context fill)**: Lower means less need to compact or summarize during long conversations.
- **Messages / turns (Messages/turns)**: lower means less back-and-forth
- **Retry rate (Retry rate)**: lower means fewer failed loops
- **Files modified on failure**: lower means a smaller area is changed if a correction fails

> [!CAUTION]
> If any important metric gets worse, roll back the addition.

## 10. Review before commit

Use `sober-review` for non-trivial changes. It is a checklist, not an auto-fixer.

Ask for a read-only review:
```text
Run the sober-review checklist on this diff.
Report PASS or ISSUES only.
Do not edit files.
```

A good review checks correctness, scope, unnecessary complexity, style, verification, tests, and security.

## 11. Understand runtime hooks

Sober connects small local hooks to Claude Code and Codex CLI user configurations. Claude uses `~/.claude/settings.json`; Codex uses `~/.codex/hooks.json` plus Sober-owned rules linked into `~/.codex/rules/`.

| Hook | What it does |
|---|---|
| `critical-action-check` | blocks dangerous shell commands |
| `verify-gate` | warns before commit/push if code changed without verification evidence |
| `handoff-write` | writes `.claude/HANDOFF.md` when a session stops and a project git repo is available |
| `session-start` | loads safe env names and shows a short budget reminder |
| `compact-suggest` | reminds you to compact long sessions |
| `post-edit-format` | formats edited files when a formatter exists |
| `tool-failure-log` | logs repeated tool failures locally with secret redaction |

Codex runs the matching Sober hooks from `~/.codex/hooks.json`. In Codex, `sober-critical-actions.rules` is linked from `~/.sober/codex-rules/` into `~/.codex/rules/` to double-check dangerous commands.

> [!NOTE]
> The `verify-gate` hook does not block `git commit` or `push` commands. It is advisory-only, showing a warning on screen to help you avoid accidentally pushing untested code.

## 12. Use current documentation when APIs matter

Instead of old information remembered by the model, prioritize the current package documentation or API docs to prevent bugs.

```bash
sober setup
# or directly:
npm install -g ctx7
ctx7 setup --cli --claude
```

Then ask for the docs naturally in the session, for example:
```text
"Use ctx7 to find and use the latest API docs for <package name>."
```

## 13. Update or uninstall

```bash
sober install      # refresh ~/.sober, runtime symlinks, and additive hook merges
sober doctor       # confirm state
sober uninstall    # remove Sober-owned symlinks, hook entries, and ~/.sober
```

- **`sober install`**: A lightweight install that refreshes the shared `~/.sober` source, links only Sober-owned entries, and merges hooks without replacing your config.
- **`sober setup`**: A comprehensive setup command that runs `install` and downloads additional productivity tools (such as `ast-grep` and `ctx7`).

> [!NOTE]
> Project files created by `sober template` are normal project files. Remove or edit them like any other repo file.

## 14. Troubleshooting

| Symptom | First check |
|---|---|
| Claude says a hook is missing | `sober doctor`, then `sober install` |
| A search tool is missing | keep working, or run `sober setup` if the task needs it |
| Verification runs the wrong stack | run `~/.sober/scripts/verify.sh --path <subdir>` |
| Tool failures repeat | run `/analyze-failures` and re-plan |
| Output gets too long | Short report request: "Show only the results, diff, and file:line" |
