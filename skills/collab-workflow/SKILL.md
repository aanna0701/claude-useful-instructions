---
name: collab-workflow
description: >
  Claude-Codex-Gemini collaboration workflow for structured design-implement-review cycles.
  Triggers on: "work item", "work plan", "work review", "work status", "codex", "gemini",
  "hand off", "delegate", "FEAT-", "multi-agent", "claude codex collaboration",
  "implementation handoff", "design and delegate", "audit", "compare diffs",
  "release notes", "contract derivation".
---

# Claude-Codex-Gemini Collaboration Workflow

This skill manages the structured handoff between Claude (design/review), Codex (implementation), and Gemini (audit/synthesis via MCP).

## Routing

| User Intent | Route To |
|-------------|----------|
| Create/plan a work item | `/work-plan` |
| Check work item status | `/work-status` |
| Review implementation | `/work-review` |
| Summarize design docs | `gemini_summarize_design_pack` MCP tool |
| Compare branch diffs | `gemini_compare_diffs` MCP tool |
| Generate release notes | `gemini_draft_release_notes` MCP tool |
| General collab question | Answer from `rules/collab-workflow.md` |

## Workflow

```
1. Claude: /work-plan [topic]
   └─ (optional) Gemini: summarize design pack → derive contract draft
   └─ Claude: review + sign contract
2. User: hands Codex prompt to Codex
3. Codex: reads AGENTS.md + work item → implements + updates status
4. Claude: /work-status [FEAT-NNN] → checks progress
5. Claude: /work-review [FEAT-NNN]
   └─ (optional) Gemini: audit implementation → review-gemini.md
   └─ Claude: final review → review.md → MERGE/REVISE/REJECT
```

## References

- Templates: `.claude/templates/work-item/`
- Codex instructions: `AGENTS.md` (project root)
- Claude instructions: `CLAUDE.md` (project root)
- Rule: `.claude/rules/collab-workflow.md`
- Gemini MCP: `mcp/gemini-review/`
