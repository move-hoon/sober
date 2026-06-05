> **[English Version](README.md)**

[![npm version](https://img.shields.io/npm/v/getsober.svg)](https://www.npmjs.com/package/getsober)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D18-blue.svg)](https://nodejs.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![GitHub stars](https://img.shields.io/github/stars/move-hoon/sober.svg?style=social)](https://github.com/move-hoon/sober)


# Sober

![Sober preview](https://github.com/user-attachments/assets/c4113ea9-06a5-43f8-bb5c-edc45ea82364)

**Claude Code와 Codex CLI가 덜 읽고, 덜 추측하고, 더 자주 검증하도록 만드는 로컬 하네스.**

Sober는 Claude Code와 Codex CLI 같은 AI 코딩 도구를 더 일관되고 효율적으로 쓰기 위한 작고 로컬인 하네스입니다. 규칙 파일 하나, 집중된 스킬 몇 개, 가벼운 안전 훅을 설치해서 에이전트가 필요한 것만 읽고, 실제 검색 도구로 위치를 찾고, 작은 변경을 만들고, 테스트로 검증하고, 실패한 추측을 반복하지 않게 만듭니다.

새 에이전트 런타임이 아닙니다. 서비스를 띄우지 않습니다. API 키를 요구하지 않습니다. 설치 후 평소처럼 Claude Code나 Codex CLI에 작업을 요청하면, 두 런타임이 같은 작업 계약을 읽고 움직입니다.

### Before & After

- **Before Sober**: 에이전트가 파일을 통째로 읽고, 코드 위치를 추측하고, 긴 설명으로 쿼터를 씁니다.
- **After Sober**: 에이전트가 도구로 정확한 위치를 찾고, 작은 변경만 만들고, 테스트로 검증한 뒤 짧게 보고합니다.

Sober는 전체 파일 읽기, 넓은 검색, 전체 파일 재출력 대신 `grep -n`, `rg`, unified diff를 에이전트에게 강제하여 작업별 바이트 유입을 크게 줄입니다. 설계 원칙과 세부 의사결정은 [`docs/adr/`](docs/adr/)를 참고하세요.

> 💡 **사용법**: Sober를 설치한 후 평소처럼 `claude` 또는 `codex` 명령어로 코딩을 요청하세요. Sober는 별도 런타임을 켜는 도구가 아니라, 각 CLI가 읽는 규칙·스킬·훅을 연결하는 로컬 하네스입니다.

---

## 빠른 시작

```bash
npm install -g getsober@latest
sober install
sober doctor
```

설치 후 얻는 것:

- `~/.sober` 한 곳에 있는 원본
- Claude Code와 Codex CLI가 공유하는 규칙
- 각 런타임으로 링크되는 Sober 스킬
- Claude Code와 Codex hooks/rules로 제공되는 안전, 핸드오프, 포맷, 압축 알림, 실패 로그

Sober는 OS 레벨에서 프로세스를 가로채는 도구가 아니라, Claude Code와 Codex CLI의 설정 지점에 규칙·스킬·훅을 연결하는 방식으로 동작합니다.

자주 쓰는 명령:

```bash
sober install          # Sober 정책 파일을 전역(Global)에 적용 / 갱신
sober setup            # 의존성 + 선택적 Context7 / 검색·편집 툴킷 설치
sober doctor           # 설치, 의존성, 훅, 선택 도구 점검
sober template [dir]   # 특정 프로젝트(Local)에 전용 룰과 HANDOFF.md 메모리 환경 구축
sober uninstall        # Sober 심볼릭과 ~/.sober 제거
```

첫 요청 예시 (에이전트의 올바른 습관을 유도하기):

> "이 버그를 고쳐줘. 관련 위치를 먼저 찾고, 최소 변경으로 수정한 뒤 테스트까지 확인해줘."

먼저 모든 줄을 확인하고 싶다면 소스에서 설치하세요:

```bash
git clone https://github.com/move-hoon/sober.git
cd sober
bash install.sh
```

---

## Sober가 해결하는 낭비

대부분의 쿼터 낭비는 지루하고 예측 가능합니다.

| 흔한 상황 | Sober가 에이전트에게 가르치는 방식 |
|---|---|
| 한 줄 찾으려고 파일 전체 읽기 | 먼저 정확한 `file:line`을 찾기 |
| 코드 위치를 추측하기 | `ripgrep`, `ast-grep`, Probe, Serena로 검색하기 |
| 기계적 편집을 손으로 재작성 | 반복 가능한 커맨드라인 변환 쓰기 |
| 오래된 탐색 결과로 코드 변경 | 대상을 다시 확인하고 컴파일/테스트 돌리기 |
| 같은 실패 추측 재시도 | 몇 번 실패하면 멈추고 다시 계획하기 |
| 긴 설명과 전체 파일 출력 | diff, 경로, 중요한 결정만 출력하기 |
| 좋아 보인다는 이유로 도구 추가 | 전후 측정; 본전 안 나오면 제거하기 |

원칙은 간단합니다: **모델의 사고력은 판단에 쓰고, grep에는 쓰지 않는다.**

---

## Sober 루프

```text
범위가 정해진 작업 요청
  → 정확한 줄 찾기
  → 가장 작고 안전한 변경
  → 빌드/테스트로 검증
  → 짧은 핸드오프 작성
  → 무언가 추가하기 전 측정
```

이 루프는 두 런타임이 읽는 하나의 규칙 파일 [`AGENTS.md`](AGENTS.md)에 들어 있습니다. Claude Code는 `CLAUDE.md`를 통해 읽고, Codex는 `AGENTS.md`를 직접 읽습니다.

내부 정책 코드를 외울 필요는 없습니다. 쉬운 말로 Sober는 에이전트에게 이렇게 요구합니다:

1. 필요한 것만 읽기
2. 실제 도구로 검색하기 **(`search-ladder` 스킬)**
3. 기계적 편집은 도구로 처리하기 **(`edit-deterministic` 스킬)**
4. 상태를 바꾸기 전에 검증하기 **(`verify-gate` 훅)**
5. 반복 실패 후 멈추고 다시 계획하기
6. 메모리는 사람이 검토한 파일로만 남기기 **(`HANDOFF.md`)**
7. git 뒤에서 위험을 격리하기
8. 하네스 추가는 측정으로 정당화하기 **(`observe` 스킬)**
9. 출력을 짧게 유지하기 **(`caveman` 스킬)**

각 결정의 자세한 이유는 [`docs/adr/`](docs/adr/)에 기록되어 있습니다.

---

## 설치되는 것

### 저장소 폴더 구조

```text
.sober/          # 공유 원본: AGENTS, commands, rules, skills, scripts
.claude/         # Claude 템플릿과 GitHub 가시성
.codex/          # Codex 문서/예시; 실제 hooks 원본은 .sober/codex
.agents/         # Codex skills 가시성; 원본은 .sober/skills
AGENTS.md        # .sober/AGENTS.md로 연결되는 symlink
CLAUDE.md        # AGENTS.md로 연결되는 symlink
```

Sober는 `~/.sober`를 단일 원본으로 두고, Claude Code와 Codex CLI가 같은 규칙과 스킬을 읽도록 연결합니다. 각 CLI의 고유한 설정 파일 규격에 맞춰 규칙, 스킬, 훅을 안전하게 연결합니다.

```text
┌──────────────────────────────────────────────────────────────┐
│                         Sober                                │
│                    shared home: ~/.sober                     │
│                                                              │
│   ┌──────────────┬──────────────┬────────────────────────┐   │
│   │   AGENTS.md  │   skills/    │        scripts/        │   │
│   │ shared rules │ tool habits  │ safety + handoff hooks │   │
│   └──────────────┴──────────────┴────────────────────────┘   │
│             ↓              ↓                  ↓              │
│        Claude Code      Codex CLI        project template    │
│        ~/.claude        ~/.codex         AGENTS/HANDOFF      │
│             ↓              ↓                  ↓              │
│      merged settings   hooks + rules     local overrides     │
└──────────────────────────────────────────────────────────────┘
```

### 파일 트리 상세

```text
~/.sober/AGENTS.md                    # 공유 정책 원본
~/.sober/commands/*.md                # Sober 소유 Claude slash command
~/.sober/rules/*.md                   # Sober 소유 Claude rule
~/.sober/skills/<skill>/SKILL.md      # 각 스킬의 단일 원본
~/.sober/scripts/                     # 로컬 훅과 검증 스크립트
~/.sober/codex-rules/*.rules          # .sober/codex/rules에서 설치된 복사본

# Claude Code 유저 환경
~/.claude/CLAUDE.md                   # symlink, 또는 기존 파일에 ~/.sober/AGENTS.md import 추가
~/.claude/AGENTS.md                   # symlink, 또는 기존 파일에 ~/.sober/AGENTS.md import 추가
~/.claude/commands/<sober-command>.md -> ~/.sober/commands/<sober-command>.md
~/.claude/rules/<sober-rule>.md       -> ~/.sober/rules/<sober-rule>.md
~/.claude/skills/<skill>              -> ~/.sober/skills/<skill>
~/.claude/settings.json               # Sober 훅이 기존 설정에 안전하게 병합됨

# Codex CLI 유저 환경
~/.codex/AGENTS.md                    # symlink, 또는 기존 파일에 Sober 블록 주입
~/.agents/skills/<skill>              -> ~/.sober/skills/<skill>
~/.codex/hooks.json                   # Sober 훅이 추가형으로 병합됨
~/.codex/rules/sober-critical-actions.rules -> ~/.sober/codex-rules/sober-critical-actions.rules
```

프로젝트 안의 `AGENTS.md`, `.claude/`, `.codex/` 파일은 여전히 전역 설정을 덮어쓸 수 있습니다.

---

## 스킬

| 스킬 | 역할 |
|---|---|
| `karpathy` | 범위 유지: 요구사항 날조 금지, 과잉설계 금지, 무관한 수정 금지, 주변 스타일 맞추기 |
| `caveman` | 답변 압축: 결과, diff, `file:line`, 의례 생략 |
| `search-ladder` | 가장 싸고 신뢰할 수 있는 순서로 코드 찾기 |
| `edit-deterministic` | 기계적 편집을 손수 재작성 대신 도구로 처리 |
| `observe` | 도구 추가 전 컨텍스트, 비용, 재시도, 실패 측정 |
| `structure-graph` | 대형 레포 흐름 추적에서 그래프를 힌트로만 사용 |
| `sober-review` | 휴대 가능한 코드 리뷰 체크리스트; 이슈만 보고하고 편집하지 않음 |

---

## 선택 도구

Sober는 아래 도구 없이도 동작합니다. 설치하면 루프가 더 저렴해집니다.

| 도구 | 도움이 되는 이유 |
|---|---|
| `ripgrep` | 빠른 정확 텍스트 검색 |
| `ast-grep` | 구조적 코드 검색과 기계적 재작성 |
| Probe | 인덱스 없는 구조적 레포 검색 |
| Serena | LSP 기반 심볼 탐색과 편집 |
| Context7 / `ctx7` | 오래된 API 기억 대신 최신 라이브러리 문서 |
| `mgrep` | 개념 질의용 시맨틱 검색, 최후 수단 |

실행:

```bash
sober doctor
sober setup
```

Context7를 직접 설치하려면:

```bash
npm install -g ctx7
ctx7 setup --cli --claude
```

`doctor`는 현재 상태를 보여줍니다. `setup`은 빠진 필수 의존성을 설치하고 선택 통합을 제안할 수 있습니다.

---

## 코드 리뷰와 헬퍼 에이전트

Sober는 고정 리뷰어 파이프라인이 아니라 **리뷰 체크리스트**를 제공합니다.

아래 상황에서만 별도 헬퍼가 본전을 합니다:

- 사소하지 않은 변경을 fresh-eyes로 리뷰할 때
- 크고 낯선 레포를 탐색할 때
- 정말 독립적인 작업 여러 개를 병렬로 할 때

일상 작업에 고정 다중 에이전트 체인을 엮지 마세요. 아끼는 것보다 더 많은 쿼터를 쓸 때가 많습니다. 체크리스트는 `.sober/skills/sober-review`에 있고, 실제 헬퍼는 Claude Code의 네이티브 subagent, Codex 헬퍼, 또는 이미 신뢰하는 리뷰어를 쓰면 됩니다.

---

## 안전과 프라이버시

- **덮어쓰기 없는 설치 (Additive)**: Sober는 기존 설정을 절대 덮어쓰지 않습니다. `settings.json`과 `hooks.json`에 자사의 안전 훅을 안전하게 병합만 하므로, 유저의 환경 변수나 권한 설정 등 기존 개발 환경은 그대로 보존됩니다.
- **순수 로컬 작동**: Sober는 외부 서버를 타지 않는 로컬 설정과 Bash 스크립트 모음입니다.
- **API 키 무관**: Sober는 사용자의 모델 API 키를 요구하거나 건드리지 않습니다.
- **위험 명령 가드레일 (Safety Guardrails)**: 위험한 쉘 명령어는 Claude Code의 훅과 Codex의 Starlark 하드 룰에 의해 실행 전에 감지하거나 차단합니다.
- **최종 통제권 보장**: 커밋 전 테스트 알림 같은 검증 알림은 조언성 경고일 뿐이며, 실제 `git commit`이나 `push` 명령을 강제로 차단하지 않습니다. 최종 통제권은 항상 유저에게 있습니다.
- **보이지 않는 메모리 금지**: 세션 메모리는 숨겨진 백그라운드 기능이 아니라 사람이 언제든 눈으로 볼 수 있는 `HANDOFF.md` 파일에 기록됩니다.
- **로컬 실패 로그 및 마스킹**: 도구 실패 로그는 로컬에만 저장되며, 저장 전 API 키나 JWT 등 흔한 시크릿 패턴을 자동으로 마스킹(Redaction)합니다.

---

## 워크플로우 배우기

- 일상 운영 가이드: [`docs/USER-MANUAL.ko.md`](docs/USER-MANUAL.ko.md)
- 설계 결정: [`docs/adr/`](docs/adr/)
- 기여 안내: [`CONTRIBUTING.md`](CONTRIBUTING.md)

---

## 개발

```bash
git clone https://github.com/move-hoon/sober.git
cd sober
npm test
npm pack --dry-run
```

## 라이선스

MIT — [LICENSE](LICENSE)를 참고하세요.
