> **[English Version](README.md)**

[![npm version](https://img.shields.io/npm/v/getsober.svg)](https://www.npmjs.com/package/getsober)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D18-blue.svg)](https://nodejs.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![GitHub stars](https://img.shields.io/github/stars/move-hoon/sober.svg?style=social)](https://github.com/move-hoon/sober)

# Sober

![Sober preview](https://github.com/user-attachments/assets/c4113ea9-06a5-43f8-bb5c-edc45ea82364)

**AI 코딩 에이전트의 토큰 낭비와 헛발질을 막아주는 규칙 패키지.**

---

## Sober가 뭔가요?

Sober는 새로운 AI가 아닙니다. 이미 사용 중인 **Claude Code** 또는 **Codex CLI**에 조용히 얹어서 AI의 작업 습관을 교정해 주는 규칙 패키지입니다.

설치 후에도 평소처럼 `claude` 또는 `codex`를 사용하면 됩니다. Sober가 뒤에서 AI에게 더 나은 습관을 가르칩니다:

- **읽기 전에 검색** — 파일 전체를 열지 않고 정확한 줄을 먼저 찾음
- **최소한만 수정** — 필요한 부분만 고침
- **테스트로 검증** — "다 했어요" 하기 전에 빌드/테스트를 돌림
- **헛발질 금지** — 같은 실패를 반복하면 멈추고 다시 계획
- **짧게 보고** — 파일 전체를 쏟아내지 않고 결과만 전달

마음에 안 들면? `sober uninstall` 한 줄이면 Sober가 만든 링크, 훅, `~/.sober`만 제거하고 사용자의 기존 설정은 그대로 둡니다.

---

## 왜 써야 하나요?

AI 코딩 에이전트는 강력하지만, 예측 가능한 이유로 쿼터를 낭비합니다:

| Sober 없이 | Sober 있으면 |
|---|---|
| 한 줄 찾으려고 파일 전체 읽기 | 정확한 `file:line`을 먼저 찾기 |
| 코드 위치를 추측하기 | 검색 도구로 위치부터 확인 |
| 필요 이상으로 많이 고치기 | 가장 작고 안전한 수정만 적용 |
| 검증 없이 "끝났습니다" | 테스트/빌드로 확인한 뒤 보고 |
| 같은 실패를 반복 시도 | 멈추고, 원인 설명 후, 재계획 |
| 긴 설명문 출력 | 결과, 변경 파일, 테스트 결과만 보고 |

**목표: 모델의 사고력은 판단에 쓰고, grep에는 쓰지 않는다.**

---

## 핵심 아키텍처: 5가지 불변식

모델이 발전해도 살아남는 5개 레이어:
1. **정책 계약 (Policy Contract):** LLM을 판단의 영역에만 가두는 P0-P8 규칙.
2. **결정론 오프로드 (Deterministic Offload):** 검색, 변환, 대용량 출력은 코드와 도구에 맡깁니다.
3. **검증 게이트 & 격리 (Verification Gate & Isolation):** 검증 없는 상태 변경을 금지하고, 병렬 작업은 worktree로 격리합니다.
4. **영속적 사람 리뷰 메모리:** 불투명한 DB 대신 파일 기반 로컬 메모리(`HANDOFF.md`)를 사용합니다.
5. **관측 (Observation):** 모든 도구와 규칙 추가는 측정으로 정당화되어야 합니다.

### L0-L6 계층 아키텍처

왜 이 순서로 도구를 적용해야 하는지 보여주는 아키텍처 레이어입니다:
*   **L0 출력 절감:** Caveman (출력 압축) + Context7 (오래된 API 환각 방지)
*   **L1 검색:** ripgrep (`| head`) → Probe (구조 검색) → mgrep (개념 질의, 최후 수단)
*   **L2 편집:** ast-grep `--rewrite` (기계적) + Serena `replace_symbol` (타입 인지)
*   **L3 심볼:** Serena (LSP)
*   **L3.5 구조:** GitNexus / code-review-graph (힌트, 변경 전 검증 필수)
*   **L4 검증 & 격리:** 변경 전 1샷 검증 → 컴파일/테스트 → 턴/실패 예산 → 네이티브 worktree 격리
*   **L5 메모리:** `AGENTS.md` / `CLAUDE.md` (정적 규칙) + `.serena/memories` (아키텍처/심볼 지식) + `HANDOFF.md` (세션 상태)
*   **L6 관측:** `/context`, `/cost`, `/status` 및 KPI 로그 확인

### Sober 루프

```text
범위가 정해진 작업 요청
  → 정확한 줄 찾기
  → 가장 작고 안전한 변경
  → 빌드/테스트로 검증
  → 짧은 핸드오프 작성
  → 무언가 추가하기 전 측정
```

루프는 [`AGENTS.md`](AGENTS.md)에 정의되어 있습니다. Claude Code는 `CLAUDE.md`를 통해, Codex는 `AGENTS.md`를 직접 읽습니다.

---

## 빠른 시작

### 사전 요구사항

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 또는 [Codex CLI](https://github.com/openai/codex)가 먼저 설치되어 있어야 합니다
- Node.js 18+

### 설치

```bash
npm install -g getsober@latest
sober setup
```

### 상태 확인

```bash
sober doctor
```

### 사용 — 새로운 프로젝트에 적용하기

```bash
cd your-project
sober template .  # 프로젝트 내부에 AGENTS.md, HANDOFF.md 등을 생성합니다.
claude            # 또는: codex
```

### 어디에 무엇이 설치되나요?

사용자가 헷갈리지 않도록 설치되는 위치는 두 곳으로 나뉩니다:

1. **글로벌 (홈 디렉터리 `~/`):** `sober setup` 실행 시.
   - `~/.sober`: 정책 원본, 훅(Hook) 스크립트, 스킬 템플릿 보관.
   - `~/.claude` & `~/.codex`: Sober가 Claude와 Codex에 연결해 둔 설정(Settings)과 규칙(Rules).
2. **로컬 (프로젝트 디렉터리 `./`):** `sober template` 실행 시.
   - `your-repo/AGENTS.md`: 프로젝트 전용 행동 강령 (기본적으로 Sober의 원칙을 복사).
   - `your-repo/HANDOFF.md`: 이 프로젝트만의 작업 진척도 및 세션 연속성 메모.

명확한 목표를 가진 프롬프트로 작업을 요청하세요:

```text
로그인 타임아웃 버그를 고쳐줘. 관련 위치를 먼저 찾고, 최소한의 안전한 변경만 하고, 테스트로 검증해줘.
```

이게 끝입니다. Sober는 뒤에서 동작합니다. 매일 쓰는 명령어는 여전히 `claude` 또는 `codex`입니다.

---

## 사용 가이드

### 효과적인 프롬프트 작성법

**정지 조건 없는 넓은 프롬프트가 쿼터를 가장 많이 낭비합니다.** "완료"가 뭔지 항상 함께 정의하세요.

가장 중요한 습관: **무엇을 할지, 무엇을 건드리지 말지, 어떻게 검증할지를 같이 적으세요.**

**좋은 프롬프트:**
```text
결제 재시도 timeout 값을 3초에서 5초로 늘려줘.
그 외의 비즈니스 로직과 동작은 유지해야 해.
기존 payment 관련 테스트 코드를 실행하여 검증해줘.
```

**나쁜 프롬프트:**
```text
이 레포 정리 좀 해줘.
```

### 스킬 — 이게 뭐고 언제 쓰나요?

스킬은 터미널 명령어가 아닙니다. AI가 작업 중에 참고하는 작은 행동 지침서입니다. 스킬 이름을 직접 부를 필요 없이, 원하는 행동을 자연스럽게 요청하면 됩니다.

| 스킬 | 이런 상황에 유용 | 프롬프트 예시 |
|---|---|---|
| `karpathy` | 모든 작업 | "요청한 변경만 해줘. 관련 없는 파일은 건드리지 마." |
| `search-ladder` | 코드 찾을 때 | "먼저 관련 `file:line`을 찾아줘. 파일 전체를 읽지 마." |
| `edit-deterministic` | 반복적인 변경 | "비슷한 호출 사이트에 반복 가능한 재작성을 써줘." |
| `caveman` | 답변이 길 때 | "결과, 변경 파일, 테스트 결과, 리스크만 보고해줘." |
| `observe` | 도구/규칙 추가할 때 | "전후 측정해줘. 지표가 좋아질 때만 유지해." |
| `sober-review` | 커밋 전 점검 | "sober-review 체크리스트를 실행해줘. 이슈만 보고하고 편집하지 마." |
| `structure-graph` | 큰 낯선 레포 탐색 | "레포 구조를 파악하고, 수정 전 반드시 rg/Serena로 교차 검증해. 정적 그래프는 런타임 배선을 놓쳐." |

### 에이전트가 막혔을 때

더 밀어붙이지 말고 — 방향을 바꾸세요.

1. **작업을 더 작게 쪼개세요.**
2. **수정 전에 계획을 먼저 요청하세요**: *"코드를 수정하기 전에 3줄 계획을 먼저 작성해줘."*
3. **검색 결과를 다시 확인하세요** — 이전 결과가 오래됐을 수 있습니다.
4. **같은 아이디어가 3번 실패하면 멈추세요** — 처음부터 다시 계획을 세우세요.
5. **도구 에러가 반복되면** — Claude Code에서 `/analyze-failures`를 실행해 패턴을 분석하세요.

### 세션 핸드오프

대화가 너무 길어지면, 세션을 멈추기 전에:

```text
검증된 사실, 남은 리스크, 다음에 실행해야 할 명령어만 요약해줘.
```

Sober의 핸드오프 훅이 세션 종료 시 자동으로 `HANDOFF.md`에 현재 브랜치, 마지막 커밋, 커밋되지 않은 변경 사항을 기록합니다.

다음 세션을 시작할 때 에이전트에게 `HANDOFF.md`를 먼저 읽으라고 요청하면, 이전 작업을 이어서 시작할 수 있습니다.

### 커밋 전 리뷰

중요한 변경 사항은 읽기 전용 리뷰를 실행하세요:

```text
이 diff에 대해 sober-review 체크리스트를 실행해줘.
PASS 또는 ISSUES만 보고해줘. 직접 코드를 수정하지 마.
```

정확성, 범위, 복잡성, 스타일, 검증 여부, 보안을 검토합니다 — 코드를 건드리지 않고.

### 도구 추가 전 측정

새로운 도구, 스킬, 규칙을 추가하기 전에 전후 비교를 하세요. Claude Code에서는 Sober의 `/measure` 명령을 쓸 수 있고, Codex에서는 같은 문장을 일반 프롬프트로 쓰면 됩니다:

```text
/measure baseline
# 설정을 딱 1개만 변경
/measure after
```

주요 지표: 작업당 읽은 파일 수, 출력 토큰, 최대 컨텍스트 사용률, 재시도 빈도. **지표가 나빠지면 되돌리세요.**

---

## 명령어 모음

```bash
sober install          # 정책 파일을 전역에 적용 / 갱신
sober setup            # install + Context7 / 검색·편집 툴킷 제안
sober doctor           # 설치 상태, 의존성, 훅, 선택 도구 점검
sober template [dir]   # 프로젝트에 전용 규칙과 HANDOFF.md 추가
sober uninstall        # Sober 심볼릭 링크와 ~/.sober 제거 (깨끗한 삭제)
```

---

## 선택 도구

Sober는 아래 도구 없이도 동작합니다. 설치하면 작업 비용이 더 낮아집니다.

| 도구 | 역할 | 경계 (하지 말아야 할 것) |
|---|---|---|
| `ripgrep` | 빠른 정확 텍스트 검색 | 시맨틱/개념 검색에 사용 금지 |
| `ast-grep` | 코드 형태 기반 기계적 재작성 | 미리보기 가능한 rewrite에 사용; 구조적 레포 검색은 Probe 사용 |
| Probe | 인덱스 없는 구조적 레포 검색 | 읽기 전용; 코드 수정 불가 |
| Serena | LSP 기반 심볼 탐색과 편집 | 런타임 DI/AOP 배선 파악 불가 |
| Context7 / `ctx7` | 오래된 API 기억 대신 최신 라이브러리 문서 | 프로젝트 내부 비즈니스 로직에 사용 금지 |
| `mgrep` | 개념 질의용 시맨틱 검색 (최후 수단) | 키워드/정확도 매칭에 사용 금지 (CoREB 한계) |

```bash
sober setup       # 대화형으로 설치 제안
sober doctor      # 현재 상태 확인
```

Context7 직접 설치:

```bash
npm install -g ctx7
ctx7 setup --cli --claude
ctx7 setup --cli --universal
```

Codex MCP 모드에서 Context7 사용:

```bash
codex mcp add context7 -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY
```

---

## 안전과 프라이버시

- **추가형 설치** — 기존 설정을 절대 덮어쓰지 않음; Sober 훅만 병합
- **런타임은 로컬** — Sober 호스팅 서비스 없음; setup 중 사용자가 선택한 선택 도구는 다운로드될 수 있음
- **API 키 불필요** — 모델 인증 정보를 요구하거나 건드리지 않음
- **안전 가드레일** — 위험한 명령은 훅(Claude)과 Starlark 규칙(Codex)으로 차단
- **최종 통제권** — 검증 알림은 조언용; `git commit`을 강제로 막지 않음
- **숨겨진 메모리 없음** — 세션 메모리는 눈에 보이는 `HANDOFF.md` 파일
- **시크릿 마스킹** — 실패 로그에 API 키와 토큰을 자동으로 가려서 기록

---

## 문제 해결

| 증상 | 해결 방법 |
|---|---|
| 에이전트가 훅을 못 찾음 | `sober doctor` 확인 후 `sober install` |
| 검색 도구가 없음 | 그냥 작업 계속하거나 `sober setup`으로 설치 |
| 검증이 잘못된 스택을 실행 | `~/.sober/scripts/verify.sh --path <하위디렉터리>` |
| 도구 오류가 반복됨 | Claude Code에서 `/analyze-failures` 실행 후 재계획 |
| 출력이 너무 장황함 | *"결과, diff, file:line만 보여줘"*로 요청 |

---

<details>
<summary><strong>아키텍처 & 내부 구조</strong> (클릭하여 펼치기)</summary>

### 프로젝트 템플릿 출력

```text
your-repo/
├─ AGENTS.md          # 프로젝트 전용 헤더 + 공유 Sober spine
├─ CLAUDE.md          # AGENTS.md symlink (단일 진실원)
├─ HANDOFF.md         # 작고 리뷰 가능한 세션 상태
└─ sgconfig.yml       # 선택, --with-sgconfig 사용 시에만 생성
```

### 무엇이 설치되나요?

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

### 설치되는 파일 트리

```text
~/.sober/AGENTS.md                    # 공유 정책 원본
~/.sober/commands/*.md                # Sober 소유 Claude slash command
~/.sober/rules/*.md                   # Sober 소유 Claude rule
~/.sober/skills/<skill>/SKILL.md      # 각 스킬의 단일 원본
~/.sober/scripts/                     # 로컬 훅과 검증 스크립트
~/.sober/codex-rules/*.rules          # .sober/codex/rules에서 설치된 복사본

# Claude Code
~/.claude/CLAUDE.md                   # ~/.sober/AGENTS.md symlink 또는 관리되는 @import 블록
~/.claude/AGENTS.md                   # ~/.sober/AGENTS.md symlink 또는 관리되는 @import 블록
~/.claude/commands/<cmd>.md           → ~/.sober/commands/<cmd>.md
~/.claude/rules/<rule>.md             → ~/.sober/rules/<rule>.md
~/.claude/skills/<skill>              → ~/.sober/skills/<skill>
~/.claude/settings.json               # Sober 훅이 기존 설정에 안전하게 병합됨

# Codex CLI
~/.codex/AGENTS.md                    # Sober spine을 inline으로 포함/갱신
~/.agents/skills/<skill>              → ~/.sober/skills/<skill>
~/.codex/hooks.json                   # Sober 훅이 추가형으로 병합됨
~/.codex/rules/*.rules                → ~/.sober/codex-rules/*.rules
```

### 런타임 훅

| 훅 | 역할 |
|---|---|
| `critical-action-check` | 위험한 shell 명령 차단 |
| `verify-gate` | 검증 없이 commit/push 시도 시 경고 (조언용) |
| `handoff-write` | 세션 종료 시 `HANDOFF.md` 기록 |
| `session-start` | 안전한 환경 변수 로드 및 예산 안내 |
| `compact-suggest` | 컨텍스트가 길어지면 압축 제안 |
| `post-edit-format` | 편집된 파일을 포맷터로 자동 정리 |
| `tool-failure-log` | 도구 실패를 시크릿 마스킹 후 로컬 로그에 기록 |

Codex는 `~/.codex/hooks.json`을 통해 동일한 훅을 실행합니다. `sober-critical-actions.rules`가 위험한 명령을 추가로 확인합니다.

</details>

---

## 코드 리뷰와 헬퍼 에이전트

Sober는 고정 리뷰어 파이프라인이 아니라 **리뷰 체크리스트**를 제공합니다.

별도 헬퍼가 본전을 하는 경우: 사소하지 않은 변경의 fresh-eyes 리뷰, 큰 낯선 레포 탐색, 진짜 독립적인 작업의 병렬 처리.

일상 작업에 고정 다중 에이전트 체인은 쿼터를 더 쓸 때가 많습니다. 체크리스트는 `.sober/skills/sober-review`에 있고, 헬퍼는 Claude Code의 네이티브 subagent나 Codex 헬퍼를 쓰면 됩니다.

---

## 개발

```bash
git clone https://github.com/move-hoon/sober.git
cd sober
npm test
npm pack --dry-run
```

설계 결정: [`docs/adr/`](docs/adr/) · 기여 안내: [`CONTRIBUTING.md`](CONTRIBUTING.md)

## 라이선스

MIT — [LICENSE](LICENSE)를 참고하세요.
