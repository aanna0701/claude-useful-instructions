# init-docs — Initialize Project Documentation Structure

Create MkDocs-based doc site structure (numbered hierarchy + Diataxis) and work item structure (`work/`), with auto-generated mkdocs.yml and category index files.

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
- Include work item structure (`work/`) — default: yes

---

## Step 2: Read Rules

Must Read:
```
skills/diataxis-doc-system/references/site-architecture.md
```

Use its folder structure, mkdocs.yml template, and index.md templates as the basis.

---

## Step 3: Create Folder Structure

Per `site-architecture.md` §1. Create folders:

```bash
mkdir -p docs/{00_context,10_architecture/{adr,rfc},20_implementation,30_guides/{tutorials,howto},40_operations,90_archive}
```

Create `index.md` per category using templates from `site-architecture.md` §4.

### Work item structure (when work/ included)

Per `site-architecture.md` §7. Create directories and `work/index.md` with overview, workflow diagram, and directory table.

---

## Step 4: Generate mkdocs.yml

Per `site-architecture.md` §2, using Step 1 project info:

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

Single Source of Truth for all project terminology. Add terms here before using in docs; link here instead of defining inline.

| Term | Definition | Synonyms (do not use) |
|------|------------|----------------------|
| | | |
```

---

## Step 6: Create docs/index.md

Per `site-architecture.md` §2 index.md template, using Step 1 project info for title and description. Include document map table and quick-start links.

---

## Step 7: Create 90_archive/index.md

Per `site-architecture.md` §5 archive rules and template.

---

## Step 8: CI/CD Files (optional)

Ask user:
> "Set up GitHub Actions for auto-deploy (gh-pages) and link checking?"

If yes, create `.github/workflows/docs.yml` and `.github/workflows/docs-lint.yml` per `site-architecture.md` §6.

---

## Step 9: Completion Report

List created items:

```
Documentation structure initialized
─────────────────────────────────
Project:  [project name]
Created:
  docs/           index.md, glossary.md, category indexes
  work/           index.md + subdirectories (if included)
  mkdocs.yml      CREATED
  CI/CD           [CREATED / SKIPPED]
─────────────────────────────────
Next steps:
  pip install mkdocs-material       # Install MkDocs
  mkdocs serve                      # Local preview
  /write-doc [topic]                # Write Diataxis doc
  /write-doc work-item [topic]      # Create Work Item bundle
  /write-doc task [topic]           # Write standalone Task
  /write-doc contract [topic]       # Write standalone Contract
```
