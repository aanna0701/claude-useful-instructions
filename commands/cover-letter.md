
# Cover Letter Agent (자소서 Multi-Agent Pipeline)

3-stage pipeline for career-level (경력직) Korean cover letters using NotebookLM as an AI reasoning engine.

```
[Stage 1/2] Context & Career Docs  ──→  Session Split  ──→  [Stage 3] Cover Letter Writing
  NLM synthesis queries for extraction/analysis    NLM upload        Writer-Reviewer loop
```

## Prerequisites
- NotebookLM MCP connected (`https://github.com/jacob-bd/notebooklm-mcp-cli`)
- "자소서" notebook with CV, portfolio, project descriptions, papers, etc. uploaded

## NLM Connection Failure Fallback

If NLM MCP call fails:
1. Output: `⚠️ NotebookLM 연결이 끊어졌습니다 (토큰 만료 가능성). nlm login으로 재인증하면 품질이 올라갑니다.`
2. Proceed using user-provided text + conversation context. Skip NLM steps.
3. If NLM recovers mid-session, switch to NLM-assisted mode immediately.

---

## Session Split (Required)

**Stage 1/2 and Stage 3 must run in separate chat sessions.**

Stage 1/2's long context degrades Stage 3 quality. Upload results to NLM and start Stage 3 in a new chat.

**Output after Stage 1/2 completion:**
> ✅ Stage 1/2 완료 — 컨텍스트 정리, 경력 기술서, 인사 관점 에세이가 NotebookLM에 저장되었습니다.
>
> 📌 **자소서 작성(Stage 3)은 새 채팅에서 시작해주세요.**
> 새 채팅에서 "자소서 써줘"라고 입력하면 바로 시작합니다.

If user requests Stage 3 in the same chat, re-output the above notice. Proceed if user insists, with a quality warning.

## Reuse Guard (Required — before Stage 1/2)

**Before running Stage 1 or Stage 2, always check the NLM source list first.**

```
nlm source list "자소서"
```

| Found source | Action |
|-------------|--------|
| `컨텍스트_정리_*` | Skip Stage 1 — "기존 컨텍스트 정리 문서를 재사용합니다 (YYYYMMDD_HHMM). 다시 생성하려면 '재생성'이라고 입력하세요." |
| `경력_기술서_*` + `인사관점_에세이_*` | Skip Stage 2 — "기존 경력 기술서/에세이를 재사용합니다 (YYYYMMDD_HHMM). 다시 생성하려면 '재생성'이라고 입력하세요." |
| None found | Run the stage normally |

**If user inputs '재생성'**: delete existing source, then regenerate.

```
nlm source delete "자소서" --title "컨텍스트_정리_YYYYMMDD_HHMM"
```

If multiple exist: use the most recent date as the reuse candidate.

---

## Stage Gate (Required)

Before entering Stage 3, verify in NLM:
- `컨텍스트_정리_*` (Stage 1) / `경력_기술서_*` (Stage 2) / `인사관점_에세이_*` (Stage 2)

**If any is missing: block Stage 3 entry → run the missing stage first.**

---

# Stage 1: Context Extraction

Read `~/.claude/commands/references/stage1-context-extraction.md` for full instructions.

---

# Stage 2: Career Description & Essay

Read `~/.claude/commands/references/stage2-career-docs.md` for full instructions.

---

# Stage 3: Cover Letter Writing (Multi-Agent Loop)

### 3.0 User Input
1. Cover letter items + JD + emphasis points + character limit + target company/role
2. (Optional) User draft — Mode B: draft provided / Mode C: revised draft for re-evaluation

**Mode B/C**: If user draft is provided, skip Writer and run Reviewer first. Writer acts as editor.

### 3.1 Writer → delegate to `cover-letter-writer` agent

### 3.2 Reviewer → delegate to `cover-letter-reviewer` agent

### 3.3 Iteration Loop

**⚠️ Always run exactly 3 iterations. No exceptions. Max 5.**

```
iteration = 0, best_score = 0, no_improve_streak = 0

WHILE iteration < 5:
    iteration 0: Writer draft (replace with user draft if Mode B/C)
    iteration 1+: restart from best_draft if score drops

    Reviewer evaluation (7 dimensions, 0-100 continuous)
    update best or no_improve_streak++
    iteration++

    IF iteration < 3: CONTINUE          # always run 3 times
    IF all dimensions ≥ 90: BREAK       # goal achieved
    IF no_improve_streak ≥ 3: BREAK     # plateau → use best version
```

### 3.4 Output
- Final cover letter (best version)
- Improvement log `.md` (full cover letter text + score table + feedback per iteration)

---

# Global Rules

| Rule | Detail |
|------|--------|
| **Language** | Skill/command files = English, all user-facing output = Korean |
| **NLM usage** | Stage 1: synthesis queries → AI critical processing. Stage 3 Writer: 1 JD-tailored query → 4-step judgment then write. All other stages: AI judgment only |
| **Facts** | AI self-checks against Stage 1/2 documents. No fabrication. Ask user if information is insufficient |
