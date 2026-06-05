# Sober review checklist

Check these items in priority order:

1. Correctness — logic errors, race conditions, null/None handling, unhandled errors.
2. Scope — the change does only what was asked; no unrelated edits or invented requirements.
3. Simplicity — the solution is the smallest clear change that works; no speculative abstraction.
4. Style fit — names, structure, and idioms match nearby code.
5. Verification — compile/tests or a clear equivalent were run, or the gap is explicit.
6. Tests — behavior changes have meaningful coverage or a justified reason not to.
7. Reporting — findings use `file:line`, highest severity first, with concrete fixes.
