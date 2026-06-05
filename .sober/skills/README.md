> **[한국어 버전](README.ko.md)**

# Skills — Short playbooks for the AI

Skills are short playbooks the AI pulls in when relevant to the task. They help the AI know exactly how to handle specific jobs.

## What's here
| Skill | What it does |
|---|---|
| `karpathy` | Follows four engineering rules: no fake scope, no over-building, no unrelated edits, match the style. |
| `caveman` | Keeps answers short — diffs and `file:line`, not walls of text. |
| `search-ladder` | Searches with real tools (ripgrep, ast-grep), not by guessing. |
| `edit-deterministic` | Makes mechanical/bulk edits with tools, not by hand-rewriting files. |
| `observe` | Before adding any tool, measures that it actually helps; if not, removes it. |
| `structure-graph` | Uses a dependency graph to help navigate massive, unfamiliar codebases. |
| `sober-review` | A checklist of what a code review must look for. |


Some skills keep longer details in a `references/` folder. The AI reads those only when the task needs them, so the main playbook stays small.
