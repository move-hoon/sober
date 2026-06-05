> **[한국어 버전](README.ko.md)**

# Runtime — Auto-detects your project type

This folder figures out what kind of project you're working on (like Node, JVM, Go, Rust, or Python). It runs the correct build and test commands automatically, so you don't have to configure anything yourself.

## What's here
| File / Directory | What it does |
|---|---|
| `detect.sh` | Looks at your files (like `package.json` or `build.gradle`) to guess the project type. |
| `adapters/` | Teaches the verifier exactly how to build and test each different ecosystem. |
