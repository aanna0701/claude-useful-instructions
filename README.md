# claude-useful-instructions

나만의 Claude Code 설정 모음. 어느 머신에서든 `./install.sh` 한 번으로 적용됩니다.

## 구조

```
claude-useful-instructions/
├── agents/
│   ├── vla-*.md              # VLA 프로젝트 서브에이전트
│   ├── cover-letter-writer.md   # 자소서 Writer 에이전트
│   └── cover-letter-reviewer.md # 자소서 Reviewer 에이전트
├── commands/
│   ├── sync-docs.md          # /sync-docs 커맨드
│   ├── smart-git-commit-push.md # /smart-git-commit-push 커맨드
│   └── cover-letter.md       # /cover-letter 자소서 작성 시스템
├── rules/
│   ├── coding-style.md       # 코딩 스타일
│   └── vla-code-standards.md # 공통 코드 표준 (서브에이전트 공유용)
└── install.sh                # ~/.claude/ 에 설정 복사
```

## 설치

```bash
git clone https://github.com/aanna0701/claude-useful-instructions.git
cd claude-useful-instructions
./install.sh
```

## Agents (서브에이전트)

`.claude/agents/`에 마크다운 파일로 정의하면 Claude Code가 자동으로 인식합니다.

### 작성법

```yaml
---
name: agent-name
description: "이 에이전트가 처리하는 작업 설명"
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet  # sonnet, opus, haiku 중 선택
---

# Agent 이름

## 담당 영역
- `src/...` — 설명

## 코드 규칙
- 규칙 1
- 규칙 2
```

### 핵심 포인트

- **description**이 가장 중요 — Claude가 이걸 보고 언제 위임할지 결정
- **tools**: 에이전트가 사용할 수 있는 도구 제한
- **model**: 단순 작업은 `haiku`, 복잡한 작업은 `opus`로 비용 최적화
- 프로젝트별 에이전트는 `<project>/.claude/agents/`에, 전역은 `~/.claude/agents/`에 배치

### 네이밍 컨벤션

프로젝트 접두사를 붙여 범위를 명확히 합니다:

```
.claude/agents/
├── vla-capture.md   # VLA 프로젝트 — 카메라 캡처
├── vla-data.md      # VLA 프로젝트 — 데이터 파이프라인
├── vla-model.md     # VLA 프로젝트 — 모델 아키텍처
├── vla-train.md     # VLA 프로젝트 — 학습
├── vla-eval.md      # VLA 프로젝트 — 평가
└── vla-infra.md     # VLA 프로젝트 — 인프라
```

패턴: `<project>-<domain>.md` (예: `vla-data`, `web-frontend`, `api-auth`)

### 예시: 도메인 분할 패턴

```
.claude/agents/
├── web-frontend.md   # React, UI 상태, 스타일링
├── web-backend.md    # API, 서버 로직, DB
└── web-infra.md      # Docker, CI/CD, 스크립트
```

CLAUDE.md에 라우팅 규칙을 추가하면 자동 위임:

```markdown
## 서브에이전트 라우팅
- frontend 관련 작업 → web-frontend 에이전트
- API/서버 작업 → web-backend 에이전트
- Docker/배포 작업 → web-infra 에이전트
```

## Rules (공유 규칙)

`rules/` 디렉토리에 코드 표준 파일을 넣으면 `install.sh`가 `~/.claude/rules/`로 복사합니다.

### 서브에이전트 규칙 적용 패턴

서브에이전트는 `CLAUDE.md`나 `.claude/rules/`를 자동으로 읽지 않습니다. 에이전트 정의에 반드시 Read 지시를 넣어야 합니다:

```markdown
## 필수 선행 작업

코드를 수정하기 전에 반드시 다음 파일을 Read하라:
1. `CLAUDE.md` — 프로젝트 강제 규칙
2. `.claude/rules/vla-code-standards.md` — 코드 표준
```

프로젝트별로 `.claude/rules/`에 규칙 파일을 두고, 에이전트가 이를 Read하게 하면 규칙이 일관되게 적용됩니다.

### 현재 규칙

| 파일 | 내용 |
|------|------|
| `rules/vla-code-standards.md` | pydantic vs dataclass 기준, 불변 패턴, TDD, import 순서 |

## Commands

### `/cover-letter`

NotebookLM MCP 기반 한국어 자소서 작성 멀티 에이전트 시스템입니다. **경력직(경력 채용)** 자소서에 최적화된 3단계 파이프라인으로 동작합니다.

#### 파이프라인 구조

![cover-letter pipeline](assets/cover-letter-pipeline.svg)

#### 작성 모드

| 모드 | 설명 |
|------|------|
| **Mode A** | 처음부터 새로 작성 |
| **Mode B** | 사용자가 직접 작성한 초안을 기반으로 개선 |
| **Mode C** | 이전 출력 결과를 사용자가 수정한 버전을 기반으로 개선 |

#### 평가 항목 (7개, 0-100점 연속 척도)

| # | 항목 | 설명 |
|---|------|------|
| 1 | 문법/맞춤법 | 띄어쓰기, 조사, 맞춤법 |
| 2 | 자연스러움 & 전문성 | 문장 흐름, 경력직 전문가 톤 |
| 3 | 사실 검증 | Stage 1/2 문서 대조, 수치/날짜 확인 |
| 4 | AI 스타일/과장/오버 | AI 투 표현, 과장·오버 문장 탐지 |
| 5 | 항목/경력 적합성 | 자소서 항목 답변 적절성, JD 매칭도 |
| 6 | 구성/구조 | 기승전결 서사 구조, 도입-맺음말 포괄성 |
| 7 | 글자수 준수 | 제한 내 글자수, 공간 활용률 |

#### 종료 조건

- **정상 종료**: 최소 3회 반복 AND 전 항목 90점 이상
- **정체 종료**: 3회 연속 점수 향상 없음 → 최고 점수 초안으로 제출
- 매 회차마다 `best_score` / `best_draft`를 추적해 점수 퇴행 시 최고 버전으로 복원

#### Stage 진입 옵션

어느 단계에서나 진입할 수 있습니다. Stage 1/2가 이미 완료된 경우 Stage 3부터 바로 시작 가능합니다.

#### 출력

전체 개선 과정(각 회차 초안 + Reviewer 점수표 + 피드백)을 기록한 `.md` 파일을 자동 생성합니다.

**사전 요구사항**: NotebookLM MCP 연결 (`jacob-bd/notebooklm-mcp-cli`) + "자소서" 노트북에 이력서/포트폴리오 저장

```
/cover-letter    # 자소서 작성 시작 (자소서 항목, JD, 강조사항, 글자수 입력)
```

### `/sync-docs`

프로젝트 문서를 현재 코드베이스 상태에 맞게 자동 갱신합니다.

- `.md`, `.toml`, `requirements.txt`, `package.json`, `Cargo.toml` 등 모든 명세/의존성 파일 스캔
- `git diff` 분석으로 최근 변경사항 반영
- 문서와 실제 코드 간 불일치 감지 후 업데이트

```
/sync-docs           # 변경된 모든 .md 파일 갱신
/sync-docs README.md # 특정 파일만 갱신
```

## 새 설정 추가

1. `commands/`, `agents/`, 또는 `rules/` 에 `.md` 파일 추가
2. `git commit && git push`
3. 다른 머신에서 `git pull && ./install.sh`
