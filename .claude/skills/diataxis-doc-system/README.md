# diataxis-doc-system

Technical documentation skill based on Diátaxis Framework + Work Item bundles. Automatically determines doc type across two axes (reader-oriented / execution-oriented) and delegates to specialized agents.

## Triggers

**Diátaxis axis (informational docs):**
- "write doc", "technical doc", "guide", "tutorial"
- "design doc", "RFC", "ADR"
- "API doc", "reference doc", "config reference", "CLI reference"
- "how-to guide", "documentation"

**Delivery axis (execution docs):**
- "work item", "feature item", "multi-agent"
- "task", "work order"
- "contract", "interface agreement"
- "checklist", "verification checklist"
- "review", "assessment"

## Core Principles

1. **Dual-axis separation** — Diátaxis (informational) and Delivery (execution) are orthogonal
2. **Work Item bundles** — 5 co-located files per feature for multi-agent coordination (Claude↔Codex)
3. **Type purity** — Never mix different doc types in one document
4. **Audience-driven** — Type is determined by who reads it and what they do next
5. **Docs as Code** — Markdown + Mermaid + Git; text over image files
6. **Source of Truth hierarchy** — RFC/ADR + Contract are authoritative; Briefs/Tasks are derived

## Workflow

```
User request
  → Phase 0.5: Axis determination (Diátaxis or Delivery?)
  → Phase 1/1-D: Type routing (select from types)
  → Phase 2: Agent delegation
  → Phase 3: Quality validation (common + axis-specific rules)
```

### Multi-Agent Workflow (Work Item)

```
Claude reads RFC/ADR → creates Work Item (brief + contract + checklist)
  → Codex reads brief → contract → checklist → implements → updates status
  → Claude reads implementation → writes review → merge decision
```

## File Structure

```
diataxis-doc-system/
├── SKILL.md                 ← Main workflow (Router)
├── README.md                ← This file
└── references/
    ├── common-rules.md      ← Docs as Code common rules + dual-axis model
    ├── site-architecture.md ← Doc site structure (numbering, MkDocs, governance, work/)
    ├── execution-rules.md   ← Work Item bundle + execution artifact rules
    ├── tutorial-rules.md    ← Tutorial agent rules
    ├── howto-rules.md       ← How-to Guide agent rules
    ├── explain-rules.md     ← Explanation agent rules
    ├── reference-rules.md   ← Reference agent rules
    └── writing-style.md     ← Readability/style guide
```

## Related Agents

**Diátaxis:** `doc-writer-tutorial`, `doc-writer-howto`, `doc-writer-explain`, `doc-writer-reference`

**Delivery:** `doc-writer-task` (brief + standalone task), `doc-writer-contract`, `doc-writer-checklist`, `doc-writer-review`

**Shared:** `doc-reviewer` (quality review, both axes), `diagram-writer` (Mermaid diagrams)

## Related Commands

- `/write-doc work-item [topic]` — Create Work Item bundle (brief + contract + checklist + status)
- `/write-doc [topic]` — Determine type → delegate to agent → write
- `/write-doc task [topic]` — Direct standalone Task creation
- `/write-doc contract [topic]` — Direct standalone Contract creation
- `/init-docs [path]` — Initialize doc structure (docs/ + work/)
- `/sync-docs` — Sync documentation to current codebase state
