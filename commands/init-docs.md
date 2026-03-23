# init-docs — Initialize Project Documentation Structure

Create MkDocs-based doc site structure (numbered hierarchy + Diátaxis) and execution doc structure (`planning/`), with auto-generated mkdocs.yml and category index files.

Target: $ARGUMENTS (project root path; defaults to current directory)

---

## Step 0: Precondition Check

1. If `$ARGUMENTS` is empty, use current directory as project root
2. Check if `docs/` exists:
   - Exists → Ask user: "Existing docs/ found. Merge or overwrite?"
   - Missing → Create new
3. Check if `mkdocs.yml` exists:
   - Exists → Backup, then propose merge
   - Missing → Create new

---

## Step 1: Gather Project Info

Confirm with user (skip if already in conversation):

**Required:** Project name, one-line description

**Optional (has defaults):**
- Language: en/ko — default: en
- Theme: material (default)
- Categories to include (default: all)
- Include execution docs (`planning/`) — default: yes

---

## Step 2: Read Rules

Must Read:
```
skills/diataxis-doc-system/references/site-architecture.md
```

Use its folder structure, mkdocs.yml template, and index.md templates as the basis.

---

## Step 3: Create Folder Structure

Per `site-architecture.md` "Hierarchical folder structure" section:

```bash
mkdir -p docs/{00_context,10_architecture/{adr,rfc},20_implementation,30_guides/{tutorials,howto},40_operations,90_archive}
```

Create `index.md` per category using templates from `site-architecture.md`.

### Execution doc structure (when planning/ included)

```bash
mkdir -p planning/{tasks,contracts,checklists,reviews}
```

Create `planning/index.md`:

```markdown
---
title: "Planning"
---

# Execution Artifacts

Documents for assigning, tracking, and verifying work.

## Workflow

RFC/ADR (docs/10_architecture/) -> Contract (planning/contracts/) -> Task (planning/tasks/) -> Checklist (planning/checklists/) -> Implementation -> Review (planning/reviews/) -> Docs Update (docs/)

## Directories

| Directory | Purpose | Naming |
|-----------|---------|--------|
| [tasks/](tasks/) | Work orders derived from RFC/ADR | `T-NNN-slug.md` |
| [contracts/](contracts/) | Interface/schema/SLA agreements | `{domain}-contract.md` |
| [checklists/](checklists/) | Task completion verification | `T-NNN.md` |
| [reviews/](reviews/) | Post-completion assessments | `T-NNN-review.md` |
```

---

## Step 4: Generate mkdocs.yml

Based on `site-architecture.md` "mkdocs.yml base structure" section, using Step 1 project info:

- `site_name` ← project name
- `site_description` ← project description
- `theme.language` ← selected language
- `nav` ← dynamically generated from file structure

---

## Step 5: Create glossary.md

```markdown
---
title: "Glossary"
status: published
owner: "[TBD]"
updated: [today's date]
---

# Glossary

Single Source of Truth for all project terminology.

| Term | Definition | Synonyms (do not use) |
|------|------------|----------------------|
| | | |

## Rules

1. Add new terms here before using them in docs
2. Words in "Synonyms" column must not appear in docs
3. Other docs link here instead of defining terms inline
```

---

## Step 6: Create docs/index.md

```markdown
---
title: "Home"
---

# [Project Name] Documentation

[One-line description]

## Document Map

| Category | Description |
|----------|-------------|
| [Context](00_context/index.md) | Business goals, requirements, glossary |
| [Architecture](10_architecture/index.md) | System design, tech stack, ADR |
| [Implementation](20_implementation/index.md) | API/Config/CLI specs |
| [Guides](30_guides/index.md) | Tutorials, How-to guides |
| [Operations](40_operations/index.md) | Deployment, monitoring, runbooks |
| [Archive](90_archive/index.md) | Archived documents |

## Quick Start

- New team member → [Getting Started](30_guides/tutorials/getting-started.md)
- Need to do something → [How-to Guides](30_guides/howto/)
- Understand design decisions → [Architecture](10_architecture/index.md)
- Looking for API specs → [API Reference](20_implementation/api-reference.md)
```

---

## Step 7: Create 90_archive/index.md

```markdown
---
title: "Archive"
---

# Archive

Documents no longer current, preserved for reference.

## Archive List

| Document | Original Location | Reason | Date | Replacement |
|----------|-------------------|--------|------|-------------|
| (none yet) | | | | |

## Archive Procedure

1. Set `status: deprecated` on the document
2. Move to this folder
3. Record reason in the table above
4. Optionally link replacement doc at original location
```

---

## Step 8: CI/CD Files (optional)

Ask user:
> "Set up GitHub Actions for auto-deploy (gh-pages) and link checking?"

If yes, create `.github/workflows/docs.yml` and `.github/workflows/docs-lint.yml` per `site-architecture.md` "CI/CD automation" section.

---

## Step 9: Completion Report

```
Documentation structure initialized
─────────────────────────────────
Project:  [project name]
Structure:
  docs/                             (Diátaxis - informational docs)
  ├── index.md
  ├── glossary.md
  ├── 00_context/       (index.md)
  ├── 10_architecture/  (index.md + adr/ + rfc/)
  ├── 20_implementation/(index.md)
  ├── 30_guides/        (index.md + tutorials/ + howto/)
  ├── 40_operations/    (index.md)
  └── 90_archive/       (index.md)

  planning/                         (Delivery - execution docs)
  ├── index.md
  ├── tasks/
  ├── contracts/
  ├── checklists/
  └── reviews/

  mkdocs.yml            CREATED
  CI/CD                 [CREATED / SKIPPED]
─────────────────────────────────
Next steps:
  pip install mkdocs-material       # Install MkDocs
  mkdocs serve                      # Local preview
  /write-doc [topic]                # Write Diátaxis doc
  /write-doc task [topic]           # Write Task
  /write-doc contract [topic]       # Write Contract
```
