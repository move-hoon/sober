# Deterministic Edit — patterns

## ast-grep rewrite metavariables
- `$X` — single node capture, reused in rewrite.
- `$$$` — variadic (arg lists, statement bodies).
- `--lang` — required for correct parsing.

```bash
# rename a call across the tree (preview → apply)
ast-grep -p 'oldApi.call($$$ARGS)' --rewrite 'newApi.call($$$ARGS)' --lang ts
ast-grep -p 'oldApi.call($$$ARGS)' --rewrite 'newApi.call($$$ARGS)' --lang ts -U

# add awaited wrapper
ast-grep -p 'fetchUser($ID)' --rewrite 'await fetchUser($ID)' --lang ts

# project rules file (optional)
ast-grep scan -r sgconfig.yml
```

## Serena symbol edits
1. `find_symbol "ClassName/methodName"` — exact location, no file dump.
2. Inspect minimal context (signature + body only).
3. `replace_symbol_body` — replace one definition; LSP keeps references consistent.
4. Verify with `scripts/verify.sh`.

## When to NOT use a tool
- A one-off, judgment-heavy change touching a few lines → plain `Edit` is cheaper than crafting a pattern.
- Cross-cutting refactor with semantic naming decisions → plan first (native plan mode), then edit.

## Situational transformers (opt-in, narrow use — spec §4 add-ons)
Beyond `ast-grep`/Serena, adopt only when a specific job recurs and `/measure` justifies it:
- **OpenRewrite** — large JVM/Spring migrations (recipe-based).
- **Semgrep** — rule-based code search/transform with security rules.
- **Comby** — language-agnostic structural rewrite.
Not bundled; reach for them per job, not by default.

## Reversibility
Every batch transform sits behind a git boundary. If verification regresses, `git revert` the boundary (P6/P7).
