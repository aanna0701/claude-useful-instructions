# Common Rules: Docs as Code

These rules apply to **all documents** regardless of type (Guide / Explanation / Reference).
Agents MUST Read this file before writing any document.

---

## 1. Storage & Version Control

### Single Source of Truth
- Documents live in the code repository (Git) — no copies in Confluence, Notion, etc.
- Document changes follow the same PR review process as code changes.

### File Format
- **Markdown** (.md) by default; AsciiDoc (.adoc) for complex layouts.
- Word/PDF are delivery artifacts, not source files.

### File Structure — MkDocs + Numbered Hierarchy (Always)

```
docs/
├── index.md
├── glossary.md
├── 00_context/          # Why: business goals, requirements
├── 10_architecture/     # How to build: system design, ADR
├── 20_implementation/   # What was built: API/Config/CLI specs
├── 30_guides/           # How to use: Guides by workflow
│   ├── auth/
│   ├── deploy/
│   └── ...
├── 40_operations/       # How to run: monitoring, runbook
└── 90_archive/          # Deprecated documents
```

> Numbering details: see `references/site-architecture.md`.
> `/init-docs` command auto-generates this structure.

---

## 2. Write Once, Link Everywhere (DRY)

**The most important content rule.** Each piece of information exists in exactly one canonical location.

| Content Type | Canonical Location | Other Docs |
|-------------|-------------------|------------|
| Parameter details, types, defaults | **Reference** doc | Guides link to Reference |
| Architecture rationale, trade-offs | **Explanation** doc | Guides/Reference link to Explanation |
| Step-by-step procedures | **Guide** doc | Other Guides link as prerequisite |
| Term definitions | **glossary.md** | All docs link to glossary |
| API specs | Auto-generated from code | Reference links to generated docs |

**Before writing any content**, check if it already exists elsewhere. If it does, **link to it** instead of duplicating.

---

## 3. Diagrams as Code

Diagrams are managed as **text code**, not image files — enabling Git diffs and single-line edits.

| Use Case | Tool | Reason |
|----------|------|--------|
| Quick flowcharts, sequences | **Mermaid** | Native GitHub/GitLab rendering |
| Complex UML, precise layout | **PlantUML** | Superior layout control |
| Infra/cloud topology | **Diagrams (Python)** | Cloud icon support |

> Delegate diagram creation to `diagram-architect` skill if available.

**Mermaid rules:** Full words over abbreviations (`Database` not `DB`), label arrows with conditions/relationships, use semantic colors (red=error, green=success).

---

## 4. Terminology Consistency

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

## 5. Metadata

All documents require YAML frontmatter:

```yaml
---
title: "Document Title"
type: guide | explanation | reference | task | contract | checklist | review
level: beginner | practitioner    # Guide only
workflow: "auth"                  # Guide only — workflow name
status: draft | review | published | deprecated
author: "Author"
owner: "Maintainer"               # Contact when info is stale
created: 2025-01-15
updated: 2025-03-18
tags: [auth, api]                  # From allowed list only
audience: "Backend Engineers"
---
```

**Diataxis status lifecycle:** `draft → review → published → deprecated → (move to 90_archive/)`

**Execution doc status lifecycle:** See `references/execution-rules.md`.

> Governance details (SSOT, dates, tags, ownership, pruning): see `references/site-architecture.md`.

---

## 5-1. Dual-Axis Model

The documentation system has two **orthogonal** axes:

| Axis | Question | Types | Location |
|------|----------|-------|----------|
| **Diataxis** (reader purpose) | What kind of document for which reader? | Guide, Explanation, Reference | `docs/` |
| **Delivery** (execution control) | How to control and verify this change? | Work Item bundle, Task, Contract, Checklist, Review | `work/` |

**Work Item Bundle** (primary pattern for multi-agent work): 5 co-located files in `work/items/FEAT-NNN-slug/` — brief, contract, checklist, status, review. Claude designs and reviews; Codex implements by contract.

### Cross-Axis Linking

Execution docs MUST link to related Diataxis docs (and vice versa is recommended):

- Brief/Task → source Explanation (RFC/ADR), related Reference
- Contract → related Reference (detailed spec)
- Review → reflect lessons in Explanation

> Execution doc details: see `references/execution-rules.md`.

---

## 6. Cross-linking

Document types are complementary — link actively:

```
Diataxis axis:  Guide → Reference → Explanation → Guide
Delivery axis:  RFC/ADR → Contract → Brief → Checklist → Review
Cross-Axis:     Brief ↔ Explanation, Contract ↔ Reference, Review → Explanation
```

- Use relative paths: `[Related guide](../deploy/rollback.md)`
- Absolute URLs for external links only
- `docs/` ↔ `work/` links use relative paths (e.g., `../../work/items/FEAT-001-slug/brief.md`)
- Include broken link checks in CI/CD

---

## 7. Review Checklist

### Type & Structure
- [ ] Document type is clear (one of: Guide/Explanation/Reference/Task/Contract/Checklist/Review)
- [ ] No mixed types within a single document
- [ ] YAML frontmatter complete (title, type, status, author, owner, tags)
- [ ] Guide docs have `level` and `workflow` fields
- [ ] Execution docs: source/task_id links are valid
- [ ] Diagrams use text code (Mermaid/PlantUML)

### DRY & SSOT
- [ ] No content duplicated from another document
- [ ] Parameter details linked to Reference (not copied into Guide)
- [ ] Architecture rationale linked to Explanation (not explained in Guide)
- [ ] Terms match glossary (linked, not redefined)

### Quality & Consistency
- [ ] Cross-reference links to related docs exist
- [ ] Content remains valid in 6 months (no hardcoded volatile values)

### Readability (writing-style.md)
- [ ] Headings + bold text convey full structure (scanning test)
- [ ] Active voice/imperative; one idea per sentence
- [ ] List items <= 9; nesting <= 3 levels
- [ ] Bold/Italic/Code used functionally

### Governance
- [ ] `owner` field assigned
- [ ] `tags` from allowed list only
