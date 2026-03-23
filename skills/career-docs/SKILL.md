---
name: career-docs
description: >
  Korean career document generation & refinement skill.
  Supports cover letters (자소서), career descriptions (경력기술서),
  portfolios (포트폴리오), cover letters (커버레터), and HR essays (인사관점 에세이).
  NotebookLM drafts; AI refines through a 6-step checklist and iterative review loop.
  Triggers: "자소서 써줘", "경력기술서 작성", "포트폴리오 정리", "커버레터 작성",
  "cover letter", "career description", "portfolio", "자소서 다듬어줘",
  "자소서 검토", "자기소개서", "이력서 정리"
---

# Career Document Pipeline

NotebookLM writes the initial draft; AI agents refine and evaluate it.
Supports multiple document types with shared refinement process and type-specific rules.

```
User Input (doc type + JD/context + constraints)
  → [Optional] Context Update (new CV/info → NLM merge → Gemini Polish)
  → NLM Draft Request (type-specific prompt) → Gemini Polish
  → 6-Step AI Refinement (career-docs-writer agent) → Gemini Polish
  → Reviewer Evaluation (career-docs-reviewer agent)
  → Iteration Loop (min 3, max 5, each: Writer → Gemini Polish → Reviewer)
  → Final Output
```

Every writing output passes through `gemini_polish_career_doc` for natural tone smoothing.
Fallback: if Gemini MCP is unavailable, skip all polish steps and proceed with unpolished output.

---

## Supported Document Types

| Type | Korean | Key Structure |
|------|--------|---------------|
| `cover-letter` | 자소서 (자기소개서) | 기승전결, competency framing |
| `career-desc` | 경력기술서 | Chronological, per-company chapters |
| `portfolio` | 포트폴리오 | Per-project, challenge→solution→impact |
| `cover-letter-en` | 커버레터 (영문/국문) | Hook → Value Prop → Fit → Close |
| `hr-essay` | 인사관점 에세이 | Soft-skill claims backed by cases |

> Full type definitions, NLM prompts, and structure rules: `references/doc-types.md`

---

## Prerequisites

- NotebookLM MCP connected (`https://github.com/jacob-bd/notebooklm-mcp-cli`)
- "자소서" notebook with CV, portfolio, project descriptions, papers, etc. uploaded
- Context documents (컨텍스트 정리, 경력 기술서, 인사관점 에세이) already in NLM

## NLM Connection Failure Fallback

If NLM MCP call fails:
1. Output: `⚠️ NotebookLM 연결이 끊어졌습니다 (토큰 만료 가능성). nlm login으로 재인증하면 품질이 올라갑니다.`
2. Ask user to paste their draft manually. Skip NLM draft step.
3. If NLM recovers mid-session, switch to NLM-assisted mode immediately.

---

## Context Update (Conditional)

**Trigger**: User provides new CV, portfolio update, or new project info alongside their request.

When new material is provided:
1. Query NLM to cross-reference new info against existing context
2. Generate an updated context/career doc incorporating the delta
3. **Gemini Polish**: `gemini_polish_career_doc(updated_doc, doc_type, 0)` — smooth the merged context doc for natural tone before uploading
4. Upload the polished version to NLM (overwrite old source)
5. Proceed with draft request using the refreshed context

When no new material is provided: skip — use existing NLM sources as-is.

---

## Step 0: User Input

Collect from user:
1. **문서 유형** — which document type? (auto-detect from request if obvious)
2. **항목/주제** — specific question, section, or topic to address
3. **JD / 지원 직무** — target company, role, job description
4. **강조 포인트** — emphasis points (optional)
5. **글자수 제한** — character limit, spaces included (optional for portfolio)
6. **User draft** — if provided, skip NLM draft and go straight to refinement
7. **Language** — Korean (default) or English (for `cover-letter-en`)

---

## Step 1: NLM Draft Request

Query NotebookLM with a **type-specific prompt** (see `references/doc-types.md` for templates).

Common pattern:
```
nlm query "자소서" "{type-specific prompt with user inputs}"
```

After receiving the NLM draft, immediately pass it through Gemini for initial polish:

**Call**: `gemini_polish_career_doc(nlm_draft, doc_type, char_limit)`

This smooths NLM's raw output into natural prose before the Writer agent begins structural refinement. The Writer starts from a better baseline, reducing iteration count.

**If user provided their own draft**: skip NLM query but still apply Gemini Polish to the user draft before passing to Step 2.

---

## Step 2: 6-Step AI Refinement → delegate to `career-docs-writer` agent

Delegate to `career-docs-writer` agent with: document type, type-specific structure rules, JD, item/topic, emphasis points, character limit, and NLM context.

The writer applies the 6-step refinement checklist sequentially (grammar → flow → structure → terminology → tone → character count). See `references/refinement-checklist.md` for full details.

---

## Step 3: Gemini Polish (via MCP)

After the writer agent's 6-step refinement, pass the result through Gemini for natural tone polishing.

**Call**: `gemini_polish_career_doc(document, doc_type, char_limit)`

Smooths tone for natural rhythm, authentic voice, and organic flow. Preserves all facts, structure, and character count. See `POLISH_CAREER_DOC` prompt in `mcp/gemini-review/prompts.py` for full polishing principles.

**Fallback**: If Gemini MCP is unavailable, skip and proceed with unpolished output.

---

## Step 4: Reviewer Evaluation → delegate to `career-docs-reviewer` agent

---

## Step 5: Iteration Loop

**Always run at least 3 iterations. Max 5.**

```
iteration = 0, best_score = 0, no_improve_streak = 0

WHILE iteration < 5:
    iteration 0: NLM draft → Refiner (Step 2) → Gemini Polish (Step 3)
    iteration 1+: restart from best_draft if score drops

    Gemini polish (Step 3)
    Reviewer evaluation (6 dimensions, 0-100 continuous)
    update best or no_improve_streak++
    iteration++

    IF iteration < 3: CONTINUE          # always run 3 times
    IF all dimensions >= 90: BREAK      # goal achieved
    IF no_improve_streak >= 3: BREAK    # plateau → use best version
```

---

## Step 6: Final Output

- Final document (best version)
- `글자수: [N]자 / [limit]자 (공백 포함)` (if character limit applies)
- Improvement log `.md`:
  - Full text per iteration
  - Score table per iteration
  - Feedback and changes per iteration

---

## Global Rules

| Rule | Detail |
|------|--------|
| **Language** | Skill files = English. User-facing output = Korean (default) or English (if `cover-letter-en`) |
| **NLM usage** | Step 1: draft generation. Context Update: delta merge. All other steps: AI judgment only |
| **Facts** | AI self-checks against NLM context docs. No fabrication. Ask user if information is insufficient |
| **Character count** | Always count including spaces and line breaks |
