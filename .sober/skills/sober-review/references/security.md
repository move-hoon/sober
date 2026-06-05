# Security checks

Use this when a change touches authentication, authorization, payments, user data, secrets, networking, shell commands, file deletion, or persistence.

Check for:

- hardcoded secrets, tokens, credentials, or private URLs;
- missing authorization checks or trust-boundary confusion;
- unvalidated input reaching SQL, shell, file paths, templates, or network calls;
- sensitive data in logs, errors, analytics, or test fixtures;
- destructive operations without clear guardrails;
- weakened hashing, encryption, or session handling.

Report security findings first.
