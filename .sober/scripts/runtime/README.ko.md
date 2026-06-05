> **[English Version](README.md)**

# Runtime — 프로젝트 타입 자동 감지

이 폴더는 현재 작업 중인 프로젝트가 어떤 종류인지(Node, JVM, Go, Rust, Python 등) 스스로 파악합니다. 알맞은 빌드와 테스트 명령어를 자동으로 실행해주기 때문에 직접 설정할 필요가 없습니다.

## 포함된 내용
| 파일 / 폴더 | 역할 |
|---|---|
| `detect.sh` | 파일(`package.json`이나 `build.gradle` 등)을 살펴보고 프로젝트 타입을 추측합니다. |
| `adapters/` | 검증 도구에게 각 생태계별로 빌드하고 테스트하는 정확한 방법을 알려줍니다. |
