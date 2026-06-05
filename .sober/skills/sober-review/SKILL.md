---
name: sober-review
description: Portable code-review checklist. Use before a commit/PR or after a non-trivial change. Run it in a separate read-only helper when your runtime supports one; Sober ships the checklist, not a fixed reviewer.
---

# Sober Review

Use this skill to review changed code against Sober's checklist.

Sober owns the portable checklist, not the reviewer implementation. Run the checklist in a separate read-only helper when the runtime supports that:

- Claude Code: ask for a read-only subagent or your own user-level reviewer.
- Codex: ask Codex to spawn a helper/reviewer subagent, or use a custom reviewer agent you installed.
- If no helper is available, self-review with this checklist before committing.

Read `references/checklist.md` first. If the change touches security-sensitive code, also read `references/security.md`. If the change adds or changes behavior, also read `references/tests.md`.

Return only:

```text
REVIEW: <path or diff>
Verdict: PASS | CHANGES REQUESTED

- [CATEGORY] file:line — issue -> fix
```

Use `PASS` only when there are no issues. A review reports findings; it never edits files or runs deploy/build commands.
