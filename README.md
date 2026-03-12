# claude-useful-instructions

나만의 Claude Code 설정 모음. 어느 머신에서든 `./install.sh` 한 번으로 적용됩니다.

## 구조

```
claude-useful-instructions/
├── agents/
│   ├── example-frontend.md  # 프론트엔드 서브에이전트 예시
│   ├── example-backend.md   # 백엔드 서브에이전트 예시
│   └── example-infra.md     # 인프라 서브에이전트 예시
├── commands/
│   └── sync-docs.md         # /sync-docs 커맨드
└── install.sh               # ~/.claude/ 에 설정 복사
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

### 예시: 도메인 분할 패턴

```
.claude/agents/
├── frontend.md   # React, UI 상태, 스타일링
├── backend.md    # API, 서버 로직, DB
└── infra.md      # Docker, CI/CD, 스크립트
```

CLAUDE.md에 라우팅 규칙을 추가하면 자동 위임:

```markdown
## 서브에이전트 라우팅
- frontend 관련 작업 → frontend 에이전트
- API/서버 작업 → backend 에이전트
- Docker/배포 작업 → infra 에이전트
```

## Commands

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
