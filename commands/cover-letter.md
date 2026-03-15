---
name: cover-letter-agent
description: >
  Multi-agent Korean cover letter (자소서) writing skill with a 3-stage pipeline using NotebookLM MCP.
  Stage 1: Extract structured context from CV/portfolio/papers in NotebookLM.
  Stage 2: Generate a detailed career description and HR-perspective essay.
  Stage 3: Write the actual 자소서 with Writer-Reviewer multi-agent loop.
  Trigger this skill whenever the user asks to write, draft, improve, or create a Korean cover letter (자소서),
  personal statement, or job application essay. Also trigger when the user mentions 자소서, 자기소개서,
  cover letter for Korean jobs, or wants help with job application writing in Korean.
  Even if the user just says "help me write 자소서" or "자소서 써줘", use this skill.
---

# Cover Letter Agent (자소서 작성 멀티 에이전트)

3-stage pipeline for career-level (경력직) Korean cover letters using NotebookLM as an AI reasoning engine.

```
[Stage 1/2] Context & Career Docs  ──→  세션 분리 가능  ──→  [Stage 3] 자소서 작성
  NLM 합성 쿼리로 추출/분석              결과 NLM 업로드          Writer-Reviewer 루프
```

## Prerequisites
- NotebookLM MCP connected (`https://github.com/jacob-bd/notebooklm-mcp-cli`)
- "자소서" notebook with CV, 포트폴리오, 프로젝트기술서, 논문 등 업로드 완료

## NLM 연결 실패 / 토큰 만료 대응

NLM MCP 호출이 실패하면:

1. **경고:** `⚠️ NotebookLM 연결이 끊어졌습니다 (토큰 만료 가능성). nlm login으로 재인증하면 품질이 올라갑니다.`
2. **NLM 없이 진행:** 사용자가 제공한 텍스트(채팅에 붙여넣은 CV, 포트폴리오 등)와 대화 컨텍스트를 기반으로 AI 모델 자체 판단으로 모든 Stage 수행. NLM 쿼리/업로드 단계는 건너뜀.
3. **중간에 NLM 복구되면** 즉시 NLM 활용 모드로 전환.

## Session Split: Stage 1/2 vs Stage 3

**Stage 1/2와 Stage 3는 반드시 별도 채팅에서 실행한다.**

같은 채팅에서 이어가면 Stage 1/2의 긴 컨텍스트(NLM 쿼리 응답, 경력 기술서, 에세이 등)가 쌓여서 Stage 3 Writer/Reviewer의 품질이 떨어진다. Stage 1/2 결과는 NLM에 업로드되어 있으므로, 새 채팅에서 NLM만 쿼리하면 깨끗한 컨텍스트로 Stage 3를 실행할 수 있다.

**Stage 1/2 완료 후 반드시 아래 메시지를 출력:**
> ✅ Stage 1/2 완료 — 컨텍스트 정리, 경력 기술서, 인사 관점 에세이가 NotebookLM에 저장되었습니다.
>
> 📌 **자소서 작성(Stage 3)은 새 채팅에서 시작해주세요.**
> 새 채팅에서 "자소서 써줘"라고 입력하면, NotebookLM에서 저장된 결과를 불러와 바로 시작합니다.
> (같은 채팅에서 이어가면 컨텍스트가 길어져 자소서 품질이 떨어질 수 있습니다)

**Stage 1/2 이후 같은 채팅에서 "자소서 써줘"라고 요청해도**, 위 안내를 다시 보여주고 새 채팅을 권유한다. 사용자가 그래도 이어서 하겠다고 하면 진행하되, 품질 저하 가능성을 고지한다.

## Stage Gate (필수)

Stage 3 진입 전, NLM에서 아래 문서 존재 확인:
- `컨텍스트_정리_*` (Stage 1)
- `경력_기술서_*` (Stage 2)
- `인사관점_에세이_*` (Stage 2)

**하나라도 없으면 Stage 3 진입 불가 → 누락된 Stage부터 실행.**

---

# Stage 1: Context Extraction

Read `references/stage1-context-extraction.md` for full instructions.

**핵심:** NLM을 검색 DB가 아닌 **추론 엔진**으로 활용. 합성 질문으로 교차 분석.

1. **NLM 합성 쿼리** — "CV와 포트폴리오 비교해서 숨겨진 강점 찾아줘", "모든 프로젝트의 역량 패턴 분석해줘"
2. **구조화 정리** — 기술스택, 프로젝트(수치 포함), 타임라인, 강점, 학력/연구
3. **NLM 업로드** — `nlm source add "자소서" --text "..." --title "컨텍스트_정리_YYYYMMDD_HHMM"`

---

# Stage 2: Career Description & Essay

Read `references/stage2-career-docs.md` for full instructions.

**Stage 1 컨텍스트 기반으로 AI가 작성** — Stage 1에서 이미 NLM으로 충분히 추출/분석했으므로 Stage 2에서는 추가 NLM 쿼리 없이 진행.

### 2.1 상세 경력 기술서
- 연도순 (oldest → newest), 각 경력별 역할/프로젝트/수치 성과
- Stage 1 컨텍스트 정리 문서를 기반으로 AI가 직접 작성

### 2.2 인사 관점 에세이
- 협업, 리더십, 커뮤니케이션, 문제해결, 조직 기여 — 에세이 형태 (800-1500자)
- Stage 1에서 추출한 협업/리더십 사례 기반으로 AI가 작성

### 2.3 업로드 & 세션 분리
- NLM 업로드: `경력_기술서_YYYYMMDD_HHMM`, `인사관점_에세이_YYYYMMDD_HHMM`
- **사용자에게 반드시 확인**: "Stage 3를 새 세션에서 시작할까요, 이어서 할까요?"

---

# Stage 3: Cover Letter Writing (Multi-Agent Loop)

Read `references/writer-prompt.md` and `references/reviewer-prompt.md` for agent details.

### 3.0 User Input
1. 자소서 항목 + JD + 강조 사항 + 글자수 제한 + 지원 회사/직무
2. (선택) 사용자 초안 — Mode B: 초안 제공 / Mode C: 이전 결과 수정 후 재요청

**Mode B/C**: 사용자 초안이 있으면 Writer를 건너뛰고 Reviewer가 먼저 평가. Writer는 사용자의 의도/톤/표현을 존중하며 개선 (에디터 역할).

### 3.1 Writer
- **NLM 1회만 호출** (첫 iteration에서만): "이 JD에 가장 적합한 경험 3개를 근거와 함께 추천해줘"
- 이후 iteration에서는 NLM 쿼리 없이 Reviewer 피드백 기반으로 개선
- 기승전결 구조 (기/결이 모든 경험을 포괄), 소제목 최대 3개
- **역량 프레이밍 필수**: [사실/결과] → [증명하는 역량] → [직무 기여 연결]
- 경력직 전문 톤, 과장/오버 금지, 글자수 엄수

### 3.2 Reviewer
- 7개 차원 0-100 연속 점수 (25/50/75/100 고정 금지)
- 팩트체크는 Stage 1/2 문서(컨텍스트에 이미 포함)를 기반으로 AI가 자체 대조 — NLM 호출 없음
- 역량 프레이밍 검사: 결과만 나열하고 역량 연결 없으면 감점

### 3.3 Iteration Loop

**⚠️ 무조건 3회 반복. 예외 없음. 최대 5회.**

```
iteration = 0, best_score = 0, no_improve_streak = 0

WHILE iteration < 5:
    iteration 0: Writer 초안 (Mode B/C면 사용자 초안으로 대체)
    iteration 1+: 점수 하락 시 best_draft에서 재시작, 아니면 현재 버전 개선

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

# Global Rules (compact)

| Rule | Detail |
|------|--------|
| **언어** | 스킬 문서 = 영어, 모든 출력물 = 한글 |
| **톤** | 경력직 전문가 — "이 사람 일 잘하겠다" not "이 사람 오버한다" |
| **금지 표현** | 과장 (혁신적인, 폭발적인), 오버 (그 순간 깨달았습니다), 신입 톤 (열심히 하겠습니다) |
| **구조** | 기승전결, 기/결이 모든 경험 포괄, 소제목 ≤3개 (3-5단어) |
| **글자수** | 공백·줄바꿈 포함 HARD limit, 95-100% 활용 |
| **역량 프레이밍** | 결과 나열 금지 → [결과] → [역량] → [직무 기여] 연결 필수 |
| **NLM 활용** | Stage 1: 합성 쿼리 (핵심), Stage 3 Writer: JD 맞춤 1회만, 나머지: AI 자체 판단 |
| **팩트** | Stage 1/2 문서 기반 AI 자체 대조, 날조 금지, 부족하면 사용자에게 질문 |
