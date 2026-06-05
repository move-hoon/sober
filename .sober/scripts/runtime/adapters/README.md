> **[한국어 버전](README.ko.md)**

# Adapters — Language-specific build/test rules

Each file here teaches the verifier how to handle one specific ecosystem. If you need to support a new language, you can just copy an existing adapter.

## What's here
| File | What it does |
|---|---|
| `_interface.sh` | The contract — a checklist of what every adapter must include. |
| `_template.sh` | A starter copy you can use to add a new language. |
| `generic.sh` | A fallback adapter (uses `make` if nothing else matches). |
| `go.sh` | Build/test rules for Go. |
| `jvm.sh` | Build/test rules for Java/Kotlin (Gradle and Maven). |
| `node.sh` | Build/test rules for JavaScript/TypeScript (npm, pnpm, yarn, bun). |
| `python.sh` | Build/test rules for Python (pip, poetry, uv, pipenv). |
| `rust.sh` | Build/test rules for Rust (Cargo). |
