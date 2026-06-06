# ADR-011 — Minimal MCP

Status: Accepted

## Decision

MCP is default-off, not forbidden. The default path is CLI-based tools.

Exceptions are allowed only when MCP provides a substantial, practical benefit that is hard to reproduce with CLI tools, such as Serena for LSP-based type-aware refactoring.

- GitNexus is used primarily as a CLI-based structure candidate generator, not an MCP tool.
- GitNexus MCP is opt-in only.
- Any MCP or graph-derived result that influences code changes must be verified with `rg`/Probe before deep reading or editing.

## Rationale

Always-on MCP servers expand the active tool surface, increase context overhead, and make agent behavior harder to audit.

They also create a failure mode where the agent treats tool-provided summaries, static graph outputs, or retrieved context as ground truth without lexical/structural validation.

Sober prefers CLI tools because they are explicit, cheap to inspect, easy to reproduce, and easy to disable. MCP remains available only when it provides a clear practical advantage over CLI operation.
