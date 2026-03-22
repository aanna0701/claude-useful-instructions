
# Cover Letter Agent (자소서 작성 멀티 에이전트)

3-stage pipeline for career-level (경력직) Korean cover letters using NotebookLM as an AI reasoning engine.

```
[Stage 1/2] Context & Career Docs  ──→  세션 분리  ──→  [Stage 3] 자소서 작성
  NLM 합성 쿼리로 추출/분석           NLM 업로드        Writer-Reviewer 루프
```

## Prerequisites
- NotebookLM MCP connected (`https://github.com/jacob-bd/notebooklm-mcp-cli`)
- "자소서" notebook with CV, 포트폴리오, 프로젝트기술서, 논문 등 업로드 완료

## NLM 연결 실패 대응

NLM MCP 호출 실패 시:
1. `⚠️ NotebookLM 연결이 끊어졌습니다 (토큰 만료 가능성). nlm login으로 재인증하면 품질이 올라갑니다.`
2. 사용자 제공 텍스트 + 대화 컨텍스트 기반으로 AI 자체 판단으로 진행. NLM 단계 건너뜀.
3. 중간에 NLM 복구되면 즉시 활용 모드로 전환.

---

## Session Split (필수)

**Stage 1/2와 Stage 3는 반드시 별도 채팅에서 실행한다.**

Stage 1/2의 긴 컨텍스트가 Stage 3 품질을 떨어뜨리므로, 결과를 NLM에 업로드하고 새 채팅에서 Stage 3 실행.

**Stage 1/2 완료 후 출력:**
> ✅ Stage 1/2 완료 — 컨텍스트 정리, 경력 기술서, 인사 관점 에세이가 NotebookLM에 저장되었습니다.
>
> 📌 **자소서 작성(Stage 3)은 새 채팅에서 시작해주세요.**
> 새 채팅에서 "자소서 써줘"라고 입력하면 바로 시작합니다.

같은 채팅에서 요청해도 위 안내 재출력. 사용자가 고집하면 품질 저하 고지 후 진행.

## Reuse Guard (필수 — Stage 1/2 시작 전)

**Stage 1 또는 Stage 2 실행 전, 항상 NLM 소스 목록을 먼저 조회한다.**

```
nlm source list "자소서"
```

| 발견된 소스 | 처리 |
|------------|------|
| `컨텍스트_정리_*` | Stage 1 건너뜀 — "기존 컨텍스트 정리 문서를 재사용합니다 (YYYYMMDD_HHMM). 다시 생성하려면 '재생성'이라고 입력하세요." |
| `경력_기술서_*` + `인사관점_에세이_*` | Stage 2 건너뜀 — "기존 경력 기술서/에세이를 재사용합니다 (YYYYMMDD_HHMM). 다시 생성하려면 '재생성'이라고 입력하세요." |
| 없음 | 해당 Stage 정상 실행 |

**사용자가 '재생성' 입력 시**: 기존 소스 삭제 후 새로 생성.

```
nlm source delete "자소서" --title "컨텍스트_정리_YYYYMMDD_HHMM"
```

여러 개 존재 시: 가장 최근 날짜 기준으로 재사용 여부 확인.

---

## Stage Gate (필수)

Stage 3 진입 전, NLM에서 확인:
- `컨텍스트_정리_*` (Stage 1) / `경력_기술서_*` (Stage 2) / `인사관점_에세이_*` (Stage 2)

**하나라도 없으면 Stage 3 진입 불가 → 누락된 Stage부터 실행.**

---

# Stage 1: Context Extraction

Read `~/.claude/commands/references/stage1-context-extraction.md` for full instructions.

---

# Stage 2: Career Description & Essay

Read `~/.claude/commands/references/stage2-career-docs.md` for full instructions.

---

# Stage 3: Cover Letter Writing (Multi-Agent Loop)

### 3.0 User Input
1. 자소서 항목 + JD + 강조 사항 + 글자수 제한 + 지원 회사/직무
2. (선택) 사용자 초안 — Mode B: 초안 제공 / Mode C: 이전 결과 수정 후 재요청

**Mode B/C**: 사용자 초안 있으면 Writer 건너뛰고 Reviewer 먼저 평가. Writer는 에디터 역할.

### 3.1 Writer → `cover-letter-writer` 에이전트에 위임

### 3.2 Reviewer → `cover-letter-reviewer` 에이전트에 위임

### 3.3 Iteration Loop

**⚠️ 무조건 3회 반복. 예외 없음. 최대 5회.**

```
iteration = 0, best_score = 0, no_improve_streak = 0

WHILE iteration < 5:
    iteration 0: Writer 초안 (Mode B/C면 사용자 초안으로 대체)
    iteration 1+: 점수 하락 시 best_draft에서 재시작

    Reviewer 평가 (7차원, 0-100 연속)
    best 갱신 또는 no_improve_streak++
    iteration++

    IF iteration < 3: CONTINUE          # 무조건 3회 실행
    IF all dimensions ≥ 90: BREAK       # 목표 달성
    IF no_improve_streak ≥ 3: BREAK     # 정체 → best 버전 사용
```

### 3.4 Output
- 최종 자소서 (best 버전)
- 개선 기록 `.md` (각 회차별 자소서 전문 + 점수표 + 피드백)

---

# Global Rules

| Rule | Detail |
|------|--------|
| **언어** | 스킬 문서 = 영어, 모든 출력물 = 한글 |
| **NLM 활용** | Stage 1: 합성 쿼리, Stage 3 Writer: JD 맞춤 1회만, 나머지: AI 자체 판단 |
| **팩트** | Stage 1/2 문서 기반 AI 자체 대조, 날조 금지, 부족하면 사용자에게 질문 |
