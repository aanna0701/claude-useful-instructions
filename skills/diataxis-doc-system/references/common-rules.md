# Common Rules: Docs as Code

These rules apply to **all documents** regardless of type (Tutorial / How-to / Explanation / Reference).
Agents MUST Read this file before writing any document.

---

## 1. Storage & Version Control

### Single Source of Truth
- Documents live in the code repository (Git) — no copies in Confluence, Notion, etc.
- Document changes follow the same PR review process as code changes.

### File Format
- **Markdown** (.md) by default; AsciiDoc (.adoc) for complex layouts.
- Word/PDF are delivery artifacts, not source files.

### File Structure

Choose based on project scale:

**Small (< 20 docs) — Diataxis-based:**
```
docs/
├── tutorials/
├── howto/
├── explanation/
│   └── adr/
├── reference/
└── glossary.md
```

**Medium/Large (20+ docs) — Numbered + MkDocs:**
```
docs/
├── index.md
├── glossary.md
├── 00_context/          # Why: business goals, requirements
├── 10_architecture/     # How to build: system design, ADR
├── 20_implementation/   # What was built: API/Config/CLI specs
├── 30_guides/           # How to use: Tutorial + How-to
│   ├── tutorials/
│   └── howto/
├── 40_operations/       # How to run: deploy, monitoring, runbook
└── 90_archive/          # Deprecated documents
```

> Numbering details: see `references/site-architecture.md`.
> `/init-docs` command auto-generates this structure.

---

## 2. Diagrams as Code

Diagrams are managed as **text code**, not image files — enabling Git diffs and single-line edits.

| Use Case | Tool | Reason |
|----------|------|--------|
| Quick flowcharts, sequences | **Mermaid** | Native GitHub/GitLab rendering |
| Complex UML, precise layout | **PlantUML** | Superior layout control |
| Infra/cloud topology | **Diagrams (Python)** | Cloud icon support |

> Delegate diagram creation to `diagram-architect` skill if available.

**Mermaid rules:** Full words over abbreviations (`Database` not `DB`), label arrows with conditions/relationships, use semantic colors (red=error, green=success).

---

## 3. Terminology Consistency

Maintain `glossary.md` at the project root:

```markdown
| Term | Definition | Banned Synonyms |
|------|-----------|----------------|
| User | Registered end user | Member, Customer, Client |
| Workspace | Isolated environment owned by one org | Tenant, Organization, Team |
| Token | JWT string used for authentication | Key, Secret, Credential |
```

**Rules:** Add new terms to glossary first. Include terminology check in review checklists. For external-facing docs, define terms in parentheses on first use.

---

## 4. Metadata

All documents require YAML frontmatter:

```yaml
---
title: "Document Title"
type: tutorial | howto | explanation | reference | task | contract | checklist | review
status: draft | review | published | deprecated
author: "Author"
owner: "Maintainer"           # Contact when info is stale
created: 2025-01-15
updated: 2025-03-18
tags: [auth, api]              # From allowed list only
audience: "Backend Engineers"
---
```

**Diataxis status lifecycle:** `draft → review → published → deprecated → (move to 90_archive/)`

**Execution doc status lifecycle:** See `references/execution-rules.md`.

> Governance details (SSOT, dates, tags, ownership, pruning): see `references/site-architecture.md`.

---

## 4-1. Dual-Axis Model

The documentation system has two **orthogonal** axes:

| Axis | Question | Types | Location |
|------|----------|-------|----------|
| **Diataxis** (reader purpose) | What kind of document for which reader? | Tutorial, How-to, Explanation, Reference | `docs/` |
| **Delivery** (execution control) | How to control and verify this change? | Task, Contract, Checklist, Review | `planning/` |

### Cross-Axis Linking

Execution docs MUST link to related Diataxis docs (and vice versa is recommended):

- Task → source Explanation (RFC/ADR), related Reference
- Contract → related Reference (detailed spec)
- Review → reflect lessons in Explanation

> Execution doc details: see `references/execution-rules.md`.

---

## 5. Cross-linking

Document types are complementary — link actively:

```
Diataxis axis:  Tutorial → How-to → Reference → Explanation → Tutorial
Delivery axis:  RFC/ADR → Contract → Task → Checklist → Review
Cross-Axis:     Task ↔ Explanation, Contract ↔ Reference, Review → Explanation
```

- Use relative paths: `[Related guide](../howto/migrate-database.md)`
- Absolute URLs for external links only
- `docs/` ↔ `planning/` links use relative paths (e.g., `../../planning/tasks/T-001.md`)
- Include broken link checks in CI/CD

---

## 6. Review Checklist

### Type & Structure
- [ ] Document type is clear (one of: Tutorial/How-to/Explanation/Reference/Task/Contract/Checklist/Review)
- [ ] No mixed types within a single document
- [ ] YAML frontmatter complete (title, type, status, author, owner, tags)
- [ ] Execution docs: source/task_id links are valid
- [ ] Diagrams use text code (Mermaid/PlantUML)

### Quality & Consistency
- [ ] Terms match glossary
- [ ] Cross-reference links to related docs exist
- [ ] Content remains valid in 6 months (no hardcoded volatile values)

### Readability (writing-style.md)
- [ ] Headings + bold text convey full structure (scanning test)
- [ ] Active voice/imperative; one idea per sentence
- [ ] List items <= 9; nesting <= 3 levels
- [ ] Bold/Italic/Code used functionally

### Governance
- [ ] `owner` field assigned
- [ ] No duplicate information across documents (SSOT)
- [ ] `tags` from allowed list only
