> **[English Version](README.md)**

# Adapters — 언어별 빌드/테스트 규칙

이곳의 각 파일은 검증 도구에게 특정 생태계를 다루는 방법을 알려줍니다. 새로운 언어를 지원해야 한다면 기존 어댑터를 하나 복사해서 쓰면 됩니다.

## 포함된 내용
| 파일 | 역할 |
|---|---|
| `_interface.sh` | 규칙 — 모든 어댑터가 반드시 포함해야 하는 항목들의 목록입니다. |
| `_template.sh` | 새로운 언어를 추가할 때 쓸 수 있는 기본 템플릿입니다. |
| `generic.sh` | 기본 어댑터입니다 (다른 언어에 맞지 않으면 `make`를 사용합니다). |
| `go.sh` | Go를 위한 빌드/테스트 규칙입니다. |
| `jvm.sh` | Java/Kotlin(Gradle, Maven)을 위한 빌드/테스트 규칙입니다. |
| `node.sh` | JavaScript/TypeScript(npm, pnpm, yarn, bun)를 위한 빌드/테스트 규칙입니다. |
| `python.sh` | Python(pip, poetry, uv, pipenv)을 위한 빌드/테스트 규칙입니다. |
| `rust.sh` | Rust(Cargo)를 위한 빌드/테스트 규칙입니다. |
