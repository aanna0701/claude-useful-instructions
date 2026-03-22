# Stage 2: Career Description & Essay

> **Reuse Guard**: see Reuse Guard section in cover-letter.md.

AI writes directly based on Stage 1 context. **No additional NLM queries in Stage 2** (Stage 1 already extracted and analyzed sufficiently).

> **Core principle**: Stage 1 document data is source material, not output. Don't re-list data.
> **Design first** — decide which experiences to use, in what order, from what angle — then write.

## 2.0 Pre-Writing Design (Required)

Before writing, decide these three things and summarize them in one paragraph (include in output):

1. **Growth narrative design** — What is the single-line growth trajectory that summarizes the entire career?
   Example: "Domain expert → System architect → Organization leader" — arrange so each company is a chapter.
2. **Key case selection** — Pre-select 2-3 cases for the HR perspective essay. Criteria: specificity > scale > emotional resonance.
   Don't use NLM-suggested cases as-is — AI judges "why is this case stronger than the others?"
3. **Differentiation point** — What distinguishes this candidate from others with similar careers? Consistently highlight this throughout the career description.

## 2.1 Detailed Career Description

Chronological (oldest → newest). Write based on the 2.0 design.

**Item format:**
```markdown
### [Company] — [Title] (YYYY.MM ~ YYYY.MM)
[Role scope in 2-3 sentences — reveal what chapter this company represents in the growth narrative]
**주요 프로젝트 및 성과:**
- [Project name]: [specific contribution] → [quantified outcome]
**핵심 역량:** [keywords]
```

**Tone rules:** factual, data-driven, specific to personal contribution, no exaggeration.

## 2.2 HR Perspective Essay

Essay format (800-1500 characters). Write based on cases selected in 2.0.

**Topics to cover:** collaboration, leadership/mentoring, communication, problem-solving approach, organizational contribution
**Rules:**
- All claims backed by concrete examples. No empty character descriptions ("I am diligent" ✗). Show don't tell.
- Don't paste Stage 1 context cases directly — AI reconstructs them to fit the narrative flow.

## 2.3 Upload & Session Split

Upload:
```
nlm source add "자소서" --text "..." --title "경력_기술서_YYYYMMDD_HHMM"
nlm source add "자소서" --text "..." --title "인사관점_에세이_YYYYMMDD_HHMM"
```

**Output session split message** (see "Session Split" section in cover-letter.md).
