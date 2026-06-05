> **[English Version](README.md)**

# Hooks — 자동 실행 스크립트

훅(Hook)은 작업을 안전하고 깔끔하게 유지하기 위해 특정 순간에 자동으로 실행되는 작은 스크립트입니다. Claude Code는 `~/.claude/settings.json`으로, Codex는 `~/.codex/hooks.json`으로 공유 훅을 불러옵니다. 직접 실행할 필요는 없습니다.

## 포함된 내용
| 훅 | 실행 시점 | 역할 |
|---|---|---|
| `compact-suggest.sh` | 파일 편집 후 | 채팅이 너무 길어지면 압축하라고 알려줍니다. |
| `critical-action-check.sh` | 명령어 실행 전 | 위험한 명령어(`rm -rf` 등)를 일시 정지하여 검토할 수 있게 합니다. |
| `handoff-write.sh` | AI 종료 시 | 지금까지 작업한 내용을 짧게 요약해서 파일에 적어둡니다. |
| `post-edit-format.sh` | 파일 편집 후 | 방금 수정한 코드를 자동으로 깔끔하게 포맷팅합니다. |
| `session-start.sh` | AI 시작 시 | 비밀번호 유출 없이 안전하게 설정을 불러옵니다. |
| `tool-failure-log.sh` | 도구 실패 시 | 무한 루프에 빠지지 않도록 에러를 기록합니다. |
| `verify-gate.sh` | 명령어 실행 전 | 테스트하지 않고 코드를 커밋하려 하면 경고를 줍니다. |
