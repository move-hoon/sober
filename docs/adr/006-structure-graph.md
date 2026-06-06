# ADR-006: Structure graph provider

Status: Accepted

## Decision

Use GitNexus as Sober's default structure graph provider, but only through the CLI by default.

GitNexus MCP is opt-in only.

## Rationale

Sober optimizes for low context surface, deterministic verification, and rollback-friendly agent behavior. GitNexus provides useful static structure hints for large or unfamiliar repositories, but always-on MCP increases tool surface and can encourage agents to treat graph output as live context.

## Policy

- GitNexus CLI is a conditional accelerator.
- GitNexus MCP is opt-in only.
- GitNexus output is a candidate list, not evidence.
- Every candidate must be verified with `rg`/Probe before deep reading or editing.
- Runtime behavior must be confirmed with tests or framework-aware evidence.
- Embeddings are disabled by default to reduce cost and keep GitNexus in the role of a lightweight structure hint generator.
