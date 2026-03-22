# Stage 1: Context Extraction

> **Reuse Guard**: see Reuse Guard section in cover-letter.md.

Use NLM as a **reasoning engine**. Not simple extraction — ask cross-analysis synthesis questions.

## Query Strategy

| ❌ Extraction (NLM waste) | ✅ Synthesis (NLM value) |
|---|---|
| "Summarize my resume" | "Compare CV and portfolio to analyze core strength patterns" |
| "List tech stack" | "Judge the deepest area of expertise with supporting evidence" |

### Round 1 — Cross-analysis
```
"Identify 3 recurring core competency patterns across the entire career with document evidence"
"Are there hidden strengths in the portfolio that don't appear in the CV?"
"Which domain has the deepest technical expertise? Judge based on papers and project descriptions."
"Analyze common threads and growth trajectory across all projects"
```

### Round 2 — Structured extraction (with synthesis)
```
"Consolidate all documents and organize tech stack by category"
"For each project: name, duration, team size, role, tech, core challenge, quantified outcomes — merge across documents"
"Career timeline chronologically: company, title, period, key contributions"
```

### Round 3 — Gap analysis
```
"Are there any projects missing numbers or outcomes?"
"Any inconsistencies across documents (dates, role titles, numbers)?"
```

## Critical Processing of NLM Results (Required — before output)

NLM responses are **raw data**. Do not reformat them as-is. After collection, AI independently judges:

**Judgment items:**
1. **Narrative potential** — Which experiences/projects can build the strongest story? NLM doesn't know relative importance.
2. **Market rarity** — Among the listed competencies, which are genuinely rare? Devalue the common ones.
3. **NLM compression loss** — Was any nuance or context lost in synthesis? (outcomes without numbers, missing team sizes, etc.)
4. **Contradiction / fabrication detection** — Did NLM ignore cross-document inconsistencies and synthesize plausibly? Verify.
5. **Stage 3 prediction** — For which JD types will this context be strongest? Pre-tag.

**Rule:** Inline judgment results in each output section as `[AI judgment: ...]`.

---

## Output Format
```markdown
# 자소서 컨텍스트 정리
## 1. 기술 스택 (카테고리별)
## 2. 프로젝트 경험 (프로젝트별: 기간/팀/역할/기술/과제/성과)
## 3. 직무 성과 (수치화)
## 4. 경력 타임라인 (연도순)
## 5. 강점 포인트 (기술적/리더십/문제해결/도메인)
   - [AI judgment: rarity assessment + narrative potential]
## 6. NLM 분석 인사이트 → AI 재해석
   - NLM raw: "..."
   - AI judgment: (agree/correct/challenge + rationale)
## 7. Gap & 불일치 ([NLM: insufficient evidence] / [AI: compression loss suspected] distinction)
```

## Upload
After user confirmation: `nlm source add "자소서" --text "..." --title "컨텍스트_정리_YYYYMMDD_HHMM"`
