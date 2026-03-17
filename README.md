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
├── skills/
│   ├── data-pipeline-architect/  # 데이터 파이프라인 설계 스킬
│   │   ├── SKILL.md
│   │   └── references/
│   ├── mermaid-extract/          # Mermaid → draw.io 변환 (Phase 1)
│   │   ├── SKILL.md
│   │   └── scripts/
│   └── drawio-embed/             # draw.io → SVG → docs 삽입 (Phase 2)
│       ├── SKILL.md
│       └── scripts/
└── install.sh                # ~/.claude/ 에 설정 복사
```

## 설치

```bash
git clone https://github.com/aanna0701/claude-useful-instructions.git
cd claude-useful-instructions
./install.sh
```

## Skills (자동 트리거 스킬)

`.claude/skills/`에 폴더 단위로 설치되며, Claude Code가 대화 맥락에 맞춰 **자동으로 트리거**합니다.

### Agents vs Skills

| | Agents | Skills |
|---|--------|--------|
| 트리거 | 메인 Claude가 판단하여 위임 | 대화 주제에 따라 자동 로딩 |
| 범위 | 특정 작업 실행 (코드 수정, 파일 생성) | 지식 + 워크플로우 (설계, 분석, 생성) |
| 구조 | 단일 `.md` 파일 | 폴더 (SKILL.md + references/) |
| 용도 | "이 코드 수정해줘" | "이 구조 설계해줘" |

### 현재 스킬

| 스킬 | 트리거 예시 | 설명 |
|------|------------|------|
| [`data-pipeline-architect`](skills/data-pipeline-architect/) | "데이터 파이프라인 설계해줘", "ETL 구조 잡아줘" | 데이터 구조 → 8원칙 진단 → 서브에이전트 설계 → instruction 생성 |
| [`mermaid-extract`](skills/mermaid-extract/) | "mermaid를 drawio로 변환해줘", "다이어그램 추출해줘" | Phase 1: docs에서 mermaid 추출 → .drawio 파일 생성 → Cursor에서 편집 |
| [`drawio-embed`](skills/drawio-embed/) | "다이어그램 docs에 넣어줘", "mermaid를 SVG로 교체해줘" | Phase 2: 편집된 .drawio → SVG export → docs의 mermaid 블록 교체 |

### 스킬 작성법

```
skills/<skill-name>/
├── SKILL.md              ← 필수. YAML frontmatter (name, description)
├── references/           ← 선택. SKILL.md에서 필요할 때만 로딩
├── scripts/              ← 선택. 실행 가능한 헬퍼
└── assets/               ← 선택. 템플릿, 아이콘 등
```

SKILL.md의 frontmatter `description`이 트리거 판단에 가장 중요합니다:

```yaml
---
name: data-pipeline-architect
description: >
  데이터 파이프라인 구조 설계 및 서브에이전트 자동 생성 스킬.
  "데이터 파이프라인 설계해줘", "ETL 구조 잡아줘" 등에 트리거.
---
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
| `rules/coding-style.md` | 코딩 스타일 (영어, 불변성, 파일 크기, 에러 처리) |
| `rules/vla-code-standards.md` | pydantic vs dataclass 기준, 불변 패턴, TDD, import 순서 |

## Commands

### `/cover-letter`

NotebookLM MCP 기반 한국어 자소서 작성 멀티 에이전트 시스템입니다. **경력직(경력 채용)** 자소서에 최적화된 3단계 파이프라인으로 동작합니다.

#### 파이프라인 구조

![cover-letter pipeline](assets/cover-letter-pipeline.svg)

#### 💡 추천 워크플로우 (세션 분리)

**Stage 1/2 완료 후 반드시 새 채팅에서 Stage 3를 시작하세요.**

Stage 1/2의 긴 컨텍스트(NLM 쿼리 응답, 경력 기술서, 에세이)가 쌓인 채로 Stage 3를 이어가면 Writer/Reviewer 품질이 떨어집니다. Stage 1/2 결과는 NotebookLM에 저장되므로 새 채팅에서 "자소서 써줘"라고 입력하면 바로 이어서 시작됩니다.

```
채팅 A: /cover-letter  →  Stage 1 (컨텍스트 추출) + Stage 2 (경력 기술서 & 에세이)
                           ↓ NotebookLM에 저장 완료
채팅 B: "자소서 써줘"  →  Stage 3 (자소서 작성 Writer-Reviewer 루프)
```

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
| 3 | 사실 검증 | Stage 1/2 문서 기반 AI 자체 대조, 수치/날짜 확인 |
| 4 | AI 스타일/과장/오버 | AI 투 표현, 과장·오버 문장 탐지 |
| 5 | 항목/경력 적합성 | 자소서 항목 답변 적절성, JD 매칭도 |
| 6 | 구성/구조 | 기승전결 서사 구조, 도입-맺음말 포괄성 |
| 7 | 글자수 준수 | 제한 내 글자수, 공간 활용률 |

#### 종료 조건

- **정상 종료**: 최소 3회 반복 AND 전 항목 90점 이상
- **정체 종료**: 3회 연속 점수 향상 없음 → 최고 점수 초안으로 제출
- 매 회차마다 `best_score` / `best_draft`를 추적해 점수 퇴행 시 최고 버전으로 복원

#### NotebookLM 활용 전략

NLM은 **Stage 1에서 집중적으로** 사용합니다. Stage 2부터는 Stage 1에서 추출된 컨텍스트를 AI가 직접 활용해 불필요한 NLM 호출을 최소화합니다.

- **Stage 1**: 3라운드 합성 쿼리 — 패턴 분석(Round 1) → 구조화 추출(Round 2) → 갭 분석(Round 3) ← NLM 핵심 활용 단계
- **Stage 2**: NLM 추가 쿼리 없음 — Stage 1 컨텍스트 기반으로 AI가 직접 경력 기술서 & 에세이 작성
- **Stage 3 Writer**: 첫 iteration에서만 JD 맞춤 NLM 쿼리 1회 (최적 경험 소재 선정), 이후 iteration은 Reviewer 피드백 기반으로 개선
- **Stage 3 Reviewer**: NLM 호출 없음 — Stage 1/2 문서가 컨텍스트에 포함되어 있으므로 AI가 자체 대조

#### Stage 진입 옵션

어느 단계에서나 진입할 수 있습니다. Stage 1/2가 이미 완료된 경우 Stage 3부터 바로 시작 가능합니다.

#### 출력

전체 개선 과정(각 회차 초안 + Reviewer 점수표 + 피드백)을 기록한 `.md` 파일을 자동 생성합니다.

#### NotebookLM MCP 설치

**설치**

```bash
# uv 사용 (권장)
uv tool install notebooklm-mcp-cli

# pip 사용
pip install notebooklm-mcp-cli
```

**로그인**

```bash
# 브라우저를 먼저 완전히 닫은 후 실행
nlm login
# → 브라우저가 열리면 Google 계정으로 로그인 → SUCCESS 메시지 확인
```

**Cursor에 MCP 등록**

```bash
nlm setup add cursor
# ~/.cursor/mcp.json 에 설정이 자동으로 추가됨
```

**Claude Code에 MCP 등록** (`~/.claude/mcp.json` 수동 추가)

```json
{
  "mcpServers": {
    "notebooklm": {
      "command": "nlm",
      "args": ["serve"]
    }
  }
}
```

**진단**

```bash
nlm doctor
```

#### NLM 연결 실패 대응

NLM MCP 호출이 실패하면 자동으로 **Graceful Degradation** 모드로 전환합니다. 사용자가 채팅에 붙여넣은 CV, 포트폴리오 텍스트와 대화 컨텍스트를 기반으로 모든 Stage를 계속 진행하고, NLM 쿼리/업로드 단계는 건너뜁니다. 중간에 NLM이 복구되면 즉시 NLM 활용 모드로 전환합니다.

```
⚠️ NotebookLM 연결이 끊어졌습니다 (토큰 만료 가능성).
nlm login으로 재인증하면 품질이 올라갑니다.
```

#### 세션 분리 (필수)

Stage 1/2(컨텍스트 추출 + 경력 기술서 작성)와 Stage 3(자소서 작성)은 **반드시 별도 채팅**에서 실행합니다. Stage 1/2의 긴 컨텍스트가 쌓이면 Stage 3 품질이 떨어지기 때문입니다. Stage 1/2 완료 후 새 채팅에서 "자소서 써줘"라고 입력하면 NotebookLM에 저장된 결과를 불러와 바로 시작됩니다.

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

### `/smart-git-commit-push`

변경사항을 분석해 기능별로 자동 분리 커밋 후 push합니다.

```
/smart-git-commit-push         # 현재 브랜치에 커밋+푸시
/smart-git-commit-push main    # main 브랜치로 푸시
```

## 새 설정 추가

1. `commands/`, `agents/`, `rules/`, 또는 `skills/` 에 파일 추가
2. `git commit && git push`
3. 다른 머신에서 `git pull && ./install.sh`
