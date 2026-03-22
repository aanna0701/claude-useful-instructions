# career-docs

Korean career document generation & refinement skill using NotebookLM + AI agents.

## Supported Document Types

- **자소서** (자기소개서) — cover letter items
- **경력기술서** — detailed career description
- **포트폴리오** — project portfolio
- **커버레터** — English/Korean cover letter
- **인사관점 에세이** — HR perspective essay

## Trigger

- "자소서 써줘", "경력기술서 작성", "포트폴리오 정리"
- "커버레터 작성", "cover letter", "자소서 다듬어줘"
- "자소서 검토", "이력서 정리"

## Workflow

```
User Input (doc type + JD/context + constraints)
  → [Optional] Context Update (new CV/info → NLM merge)
  → NLM Draft (type-specific prompt)
  → 6-Step AI Refinement (career-docs-writer agent)
  → Reviewer Evaluation (career-docs-reviewer agent)
  → Iteration Loop (min 3, max 5)
  → Final Output
```

## File Structure

```
career-docs/
├── SKILL.md                    ← Main workflow (always loaded)
├── README.md                   ← This file
└── references/
    ├── refinement-checklist.md ← 6-step refinement rules (shared)
    └── doc-types.md            ← Per-type structure, prompts, weights
```

## Agents

| Agent | Role |
|-------|------|
| `career-docs-writer` | Refines NLM draft through 6-step checklist |
| `career-docs-reviewer` | Evaluates quality across 6 dimensions |
