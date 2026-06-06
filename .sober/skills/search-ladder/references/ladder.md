# Search Ladder — recipes

## Rung 1: ripgrep (lexical)
```bash
rg -n "pattern" path/            # line numbers
rg -n -t ts "pattern"            # language filter
rg -l "pattern"                  # files only
rg -n -A2 -B0 "pattern" | head   # minimal context
rg -n --glob '!**/node_modules/**' "pattern"
```
Use when: exact identifier/string/regex. Cheapest, always present.
- **Token lever (P0):** pipe high-frequency search to `| head -50`. `-C N` (context lines) inflates output ~2–6× — use only when you actually need surrounding lines.

## Rung 2: Probe (structural repo search)
```bash
probe search "session token refresh" ./src --max-results 20
```
Use when: matching shape (signatures, call patterns, nesting) where regex is brittle.

## Rung 3: mgrep (semantic) — last resort
```bash
mgrep "concept you cannot name as a token" src/
```
Use only when the target has no stable lexical/structural handle. Highest token/noise cost (P1). `grepai` is an equivalent semantic alternative — embeddings go stale and degrade on short keyword queries (CoREB), so semantic stays last.

## Fallback discipline
- `probe` absent → `rg` + manual narrowing.
- Never escalate to semantic to avoid writing a precise lexical query.
