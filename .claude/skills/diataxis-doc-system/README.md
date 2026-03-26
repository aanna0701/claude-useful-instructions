# diataxis-doc-system

Technical documentation skill based on Diátaxis Framework + Work Item bundles. Automatically determines doc type across two axes (reader-oriented / execution-oriented) and delegates to specialized agents.

## Triggers

**Diátaxis axis (informational docs):**
- "write doc", "technical doc", "guide", "tutorial", "how-to guide"
- "design doc", "RFC", "ADR"
- "API doc", "reference doc", "config reference", "CLI reference"
- "documentation", "doc structure", "docs init", "MkDocs"

**Delivery axis (execution docs):**
- "work item", "feature item", "multi-agent"
- "task", "work order"
- "contract", "interface agreement"
- "checklist", "verification checklist"
- "review", "assessment"

## Core Principles

1. **No mixed types** — Each document has exactly one purpose
2. **Write once, link everywhere** — Content exists in one canonical location; other docs link to it
3. **Topic-first organization** — Organize by domain/workflow, not by document type
4. **MkDocs always** — All projects use numbered hierarchy + MkDocs Material
5. **Dual-axis separation** — Diátaxis (informational) and Delivery (execution) are orthogonal
6. **Workflow-based guides** — Guides grouped by workflow (auth, deploy, data...), not by level
7. **Source of Truth hierarchy** — RFC/ADR + Contract are authoritative; Briefs/Tasks are derived

## Document Types

### Diátaxis Axis (3 types)

| Type | Purpose | Reader State |
|------|---------|-------------|
| **Guide** | Step-by-step procedures | Wants to accomplish a task |
| **Explanation** | Understanding "why" | Wants design rationale |
| **Reference** | Exact specs lookup | Needs parameters/types |

Guide replaces both Tutorial and How-to from classic Diátaxis. Level in frontmatter (`beginner` / `practitioner`) controls depth and tone.

### Delivery Axis (5 types)

Work Item bundle, Task, Contract, Checklist, Review — for multi-agent coordination.

## Workflow

```
User request
  → Phase 0.5: Axis determination (Diátaxis or Delivery?)
  → Phase 1: Type routing (Guide / Explanation / Reference)
  → Phase 1-W: Workflow discovery (Guide only — which workflow?)
  → Phase 2: Agent delegation
  → Phase 3: Quality validation
```

### Guide Workflow Organization

```
docs/30_guides/
├── index.md              # Workflow map (lists all workflows)
├── auth/                 # Auth workflow
│   ├── getting-started.md    # [beginner]
│   └── add-oauth-provider.md # [practitioner]
├── deploy/               # Deploy workflow
│   ├── first-deploy.md       # [beginner]
│   └── rollback.md           # [practitioner]
```

## File Structure

```
diataxis-doc-system/
├── SKILL.md                 ← Main workflow (Router)
├── README.md                ← This file
└── references/
    ├── common-rules.md      ← Docs as Code, DRY rules, dual-axis model
    ├── site-architecture.md ← MkDocs structure, numbering, workflow map, governance
    ├── execution-rules.md   ← Work Item bundle + execution artifact rules
    ├── guide-rules.md       ← Guide agent rules (beginner + practitioner)
    ├── explain-rules.md     ← Explanation agent rules
    ├── reference-rules.md   ← Reference agent rules
    ├── writing-style.md     ← Readability/style guide
    └── execution-templates.md ← YAML frontmatter templates
```

## Related Agents

**Diátaxis:** `doc-writer-guide`, `doc-writer-explain`, `doc-writer-reference`

**Delivery:** `doc-writer-task` (brief + standalone task), `doc-writer-contract`, `doc-writer-checklist`, `doc-writer-review`

**Shared:** `doc-reviewer` (quality review), `doc-reviewer-execution` (execution artifact review), `diagram-writer` (Mermaid diagrams)

## Related Commands

- `/write-doc guide [topic]` — Write Guide (determines level + workflow)
- `/write-doc explanation [topic]` — Write Explanation (RFC/ADR)
- `/write-doc reference [topic]` — Write Reference
- `/write-doc work-item [topic]` — Create Work Item bundle
- `/write-doc task [topic]` — Direct standalone Task creation
- `/init-docs [path]` — Initialize MkDocs structure (docs/ + work/)
- `/sync-docs` — Sync documentation to current codebase state
