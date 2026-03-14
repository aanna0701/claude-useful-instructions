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

NotebookLM MCP 기반 한국어 자소서 작성 멀티 에이전트 시스템입니다.

- Writer 에이전트(초안 작성)와 Reviewer 에이전트(평가/피드백)가 반복 루프를 돌며 자소서 품질을 개선
- 7가지 평가 항목(문법, 자연스러움, 사실검증, AI스타일탈피, 항목적합성, 구성, 글자수)으로 100점 만점 채점
- 총점 76점 이상 또는 최대 5회 반복 시 종료
- 전체 개선 과정을 기록한 `.md` 파일 자동 생성

**사전 요구사항**: NotebookLM MCP 연결 + "자소서" 노트북에 이력서/포트폴리오 저장

```
/cover-letter    # 자소서 작성 시작 (항목, 강조사항, 글자수 입력)
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
