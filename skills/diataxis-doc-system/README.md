# diataxis-doc-system

Technical documentation skill based on Diátaxis Framework + Execution Artifacts. Automatically determines doc type across two axes (reader-oriented / execution-oriented) and delegates to specialized agents.

## Triggers

**Diátaxis axis (informational docs):**
- "write doc", "technical doc", "guide", "tutorial"
- "design doc", "RFC", "ADR"
- "API doc", "reference doc", "config reference", "CLI reference"
- "how-to guide", "documentation"

**Delivery axis (execution docs):**
- "task", "work order"
- "contract", "interface agreement"
- "checklist", "verification checklist"
- "review", "assessment"

## Core Principles

1. **Dual-axis separation** — Diátaxis (informational) and Delivery (execution) are orthogonal
2. **Type purity** — Never mix different doc types in one document
3. **Audience-driven** — Type is determined by who reads it and what they do next
4. **Docs as Code** — Markdown + Mermaid + Git; text over image files
5. **Source of Truth hierarchy** — RFC/ADR + Contract are authoritative; Tasks are derived

## Workflow

```
User request
  → Phase 0.5: Axis determination (Diátaxis or Delivery?)
  → Phase 1/1-D: Type routing (select from 8 types)
  → Phase 2: Agent delegation
  → Phase 3: Quality validation (common + axis-specific rules)
```

## File Structure

```
diataxis-doc-system/
├── SKILL.md                 ← Main workflow (Router)
├── README.md                ← This file
└── references/
    ├── common-rules.md      ← Docs as Code common rules + dual-axis model
    ├── site-architecture.md ← Doc site structure (numbering, MkDocs, governance, planning/)
    ├── execution-rules.md   ← Execution Artifact rules (Task/Contract/Checklist/Review)
    ├── tutorial-rules.md    ← Tutorial agent rules
    ├── howto-rules.md       ← How-to Guide agent rules
    ├── explain-rules.md     ← Explanation agent rules
    ├── reference-rules.md   ← Reference agent rules
    └── writing-style.md     ← Readability/style guide
```

## Related Agents

**Diátaxis:** `doc-writer-tutorial`, `doc-writer-howto`, `doc-writer-explain`, `doc-writer-reference`

**Delivery:** `doc-writer-task`, `doc-writer-contract`, `doc-writer-checklist`, `doc-writer-review`

**Shared:** `doc-reviewer` (quality review, both axes), `diagram-writer` (Mermaid diagrams)

## Related Commands

- `/write-doc [topic]` — Determine type → delegate to agent → write
- `/write-doc task [topic]` — Direct Task creation (Delivery axis)
- `/write-doc contract [topic]` — Direct Contract creation
- `/init-docs [path]` — Initialize doc structure (docs/ + planning/)
- `/sync-docs` — Sync documentation to current codebase state
