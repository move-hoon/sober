---
name: cli-patterns
description: Use token-efficient CLI patterns instead of verbose MCP output when direct shell tools are enough. Provides JSON or compact-output conventions for gh, mgrep, psql, and similar tools.
---

# CLI Patterns Skill

## Purpose
Prefer compact, stable CLI output over verbose MCP output when direct shell tools are enough.
Use JSON + jq when a tool supports it, and otherwise use the smallest practical text or CSV output mode.

## GitHub (gh)
```bash
gh pr list --json number,title | jq -c '.[]'
gh pr create --title "feat: X" --body "desc"
gh issue list --json number,title | jq -c '.[]'
```
Full reference: `@references/github-cli.md`

## Search (mgrep)
```bash
mgrep "pattern" src/
mgrep -t py "class"      # Python
mgrep -t java "public"   # Java
mgrep -t go "func"       # Go
mgrep --web "docs query"
```
Full reference: `@references/mgrep.md`

## Database
```bash
psql -t -A -F',' -c "SELECT..."
```

## Benefits
| Tool | Benefit |
|------|---------|
| gh pr list | JSON output reduces verbosity significantly |
| psql | CSV format eliminates table formatting overhead |
