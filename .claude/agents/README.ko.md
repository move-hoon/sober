> **[English Version](README.md)**

# Agents — helper 역할

이 폴더는 의도적으로 비워 둡니다. Sober는 고정 helper agent 묶음을 설치하지 않습니다. 대신 공유 규칙과 체크리스트만 두고, 별도 시야가 도움이 될 때 Claude Code나 Codex의 네이티브 방식으로 helper를 실행합니다.

## 여기에 있는 것
| 파일 / 항목 | 하는 일 |
|---|---|
| `README.md` / `README.ko.md` | 이 관리 폴더가 기본적으로 비어 있는 이유를 설명합니다. |

## helper를 쓸 때
다음처럼 별도 시야가 실제로 도움이 될 때 helper를 쓰세요.

- 서로 독립적인 여러 작업을 동시에 진행할 수 있을 때
- 낯선 큰 코드베이스를 탐색해야 할 때
- 작성자가 놓친 문제를 읽기 전용 리뷰로 확인하고 싶을 때

코드 리뷰에는 `skills/sober-review` 체크리스트가 있습니다. 런타임이 지원한다면 그 체크리스트를 별도 읽기 전용 helper에 적용하라고 요청하세요. 개인 agent는 이 Sober 관리 폴더가 아니라 각 런타임의 사용자 전역 폴더에 둡니다.

- Claude Code: `~/.claude/agents/`
- Codex: `~/.codex/agents/`

Sober가 프로젝트 관리 agent를 추가해야 한다면, 먼저 도움이 된다는 측정 근거를 만들고 installer도 의도적으로 업데이트해야 합니다.
