# Documentation Site Architecture (Information Architecture)

Defines the **hierarchy, numbering scheme, and governance rules** for MkDocs-based documentation sites.
`/init-docs` command initializes project docs according to these rules.

---

## 1. 3-Level Folder Hierarchy

The `00-99` numbering scheme enforces sort order. Numbers represent **categories**;
each category contains multiple Diataxis types (Tutorial / How-to / Explanation / Reference).

```
docs/
├── index.md                         # Doc home (project overview + doc map)
├── glossary.md                      # Glossary (SSOT)
│
├── 00_context/                      # Context: why this project
│   ├── index.md
│   ├── business-goals.md            # [Explanation]
│   ├── personas.md                  # [Reference]
│   ├── requirements.md              # [Reference]
│   └── glossary-guide.md            # [How-to]
│
├── 10_architecture/                 # Design: how to build it
│   ├── index.md
│   ├── system-overview.md           # [Explanation]
│   ├── tech-stack.md                # [Explanation]
│   ├── data-model.md                # [Reference]
│   └── adr/
│       ├── 001-database-choice.md
│       └── 002-auth-strategy.md
│
├── 20_implementation/               # Implementation: code-level details
│   ├── index.md
│   ├── api-reference.md             # [Reference]
│   ├── config-reference.md          # [Reference]
│   ├── cli-reference.md             # [Reference]
│   └── module-guide.md              # [Explanation]
│
├── 30_guides/                       # Guides: practical work
│   ├── index.md
│   ├── tutorials/                   # [Tutorial]
│   │   ├── getting-started.md
│   │   └── first-deployment.md
│   └── howto/                       # [How-to]
│       ├── migrate-database.md
│       ├── rotate-tokens.md
│       └── troubleshooting.md
│
├── 40_operations/                   # Operations: production management
│   ├── index.md
│   ├── deploy-guide.md              # [How-to]
│   ├── monitoring.md                # [Explanation]
│   ├── runbook.md                   # [How-to]
│   └── sla-reference.md             # [Reference]
│
└── 90_archive/                      # Archive: no longer valid
    ├── index.md
    └── ...
```

### Numbering Scheme

| Range | Category | Key Question |
|-------|----------|-------------|
| `00` | Context | **Why** this project? |
| `10` | Architecture | **How** to build it? (design) |
| `20` | Implementation | **What** was built? (code-level) |
| `30` | Guides | **How** to use it? (practical) |
| `40` | Operations | **How** to run it? (production) |
| `50-80` | (Reserved) | Project-specific extensions |
| `90` | Archive | Deprecated documents |

### Numbering vs Diataxis Mapping

Numbering = **topic (domain)** classification. Diataxis = **purpose** classification. They are orthogonal.

```
              Tutorial   How-to   Explanation   Reference
00_context       -          ●          ●            ●
10_architecture  -          -          ●            ●
20_implementation-          -          ●            ●
30_guides        ●          ●          -            -
40_operations    -          ●          ●            ●
```

Diataxis type is specified via the `type` field in YAML frontmatter.

Three orthogonal axes: **Domain** (numbered folders `00-90`), **Diataxis** (reader goal: Tutorial/How-to/Explanation/Reference), **Delivery** (execution artifacts in `work/`). Domain and Diataxis intersect within `docs/`; Delivery lives in a separate root — same repo, different concerns.

---

## 2. MkDocs Configuration

**Theme:** `material` with navigation tabs/sections/indexes, search suggest/highlight, TOC integration, light/dark toggle.

**Required plugins:** `search`, `tags`, `git-revision-date-localized` (with `enable_creation_date: true`).

**Required extensions:** `admonition`, `pymdownx.details`, `pymdownx.superfences` (with mermaid fence), `pymdownx.tabbed`, `attr_list`, `md_in_html`, `toc` (with permalink).

**Tags:** Define allowed tags in `extra.tags` (e.g., `auth`, `database`, `api`, `infra`, `security`).

**Nav structure** mirrors the numbered folder hierarchy: Home, Glossary, Context, Architecture (with ADR sub-section), Implementation, Guides (Tutorials + How-to), Operations, Archive.

### Category index.md Template

Each category `index.md` serves as a **document map**:

```markdown
---
title: "[Category Name]"
tags: []
---

# [Category Name]

[2-3 sentences describing what this category covers.]

## Documents

| Document | Type | Description | Last Updated |
|----------|------|-------------|-------------|
| [System Overview](system-overview.md) | Explanation | Full architecture description | 2025-03-18 |
```

> **Tip:** Add `Status` and `Owner` columns when your team needs governance tracking per document.

---

## 3. Five Governance Rules

### Rule 1: Single Source of Truth (SSOT)

Same information exists in **exactly one place**.

| Pattern | DO | DON'T |
|---------|-----|-------|
| API spec | Auto-generate from code, link from design docs | Copy-paste spec into design docs |
| Config values | One config reference file | Duplicate in README + guides |
| Term definitions | Define in `glossary.md`, link elsewhere | Redefine in each document |

Violation: if same info exists in 2+ places, designate one as canonical and replace others with links.

### Rule 2: Date & Status

Required frontmatter: `title`, `type`, `status`, `author`, `owner`, `created`, `updated`, `tags`, `audience`.
Lifecycle: `draft → review → published → deprecated → 90_archive/`

### Rule 3: Tagging

Tags surface cross-cutting concerns beyond folder structure. Lowercase kebab-case only (`auth`, `deploy`). Maintain an allowed list in `mkdocs.yml extra.tags` — no free-form tags.

### Rule 4: Ownership

Every document has an `owner` (GitHub handle or team). Owners: quarterly review published docs, update docs on code changes, handle deprecation, transfer ownership before leaving.

### Rule 5: Pruning

**Wrong information is worse than no information.** Triggers: quarterly review, `updated` > 6 months, deleted referenced code. Procedure: set `status: deprecated` with reason, move to `90_archive/`, record in `archive/index.md`.

---

## 4. Archive Rules

`90_archive/` is a **reference library**, not a graveyard.

The `archive/index.md` tracks all archived documents in a table with columns: **Document** (link), **Original Location**, **Reason**, **Date**, **Replacement** (link to successor). Each archived document must have `status: deprecated` in frontmatter plus a warning admonition block stating the replacement link, reason, and archive date.

> Canonical templates for archive index and deprecated headers: see `init-docs.md`.

---

## 5. CI/CD Automation (Optional)

**Deploy workflow** (`.github/workflows/docs.yml`): On push to `main` (paths: `docs/**`, `mkdocs.yml`), checkout with `fetch-depth: 0`, install `mkdocs-material` + `mkdocs-git-revision-date-localized-plugin`, run `mkdocs gh-deploy --force`.

**Link validation** (`.github/workflows/docs-lint.yml`): On PR, run `mkdocs build --strict` to detect broken links.

---

## 6. Execution Document Directory (`work/`)

`docs/` contains **reader-facing documentation**. `work/` contains **execution artifacts for assigning, tracking, and verifying work**.
`work/` sits outside the `00-90` numbering scheme and operates independently of Diataxis classification.

### Structure

```
work/
├── index.md              # Overview + workflow diagram
├── items/                # Work Item bundles (primary pattern)
│   └── FEAT-001-slug/
│       ├── brief.md      # What & why
│       ├── contract.md   # Implementation boundaries
│       ├── checklist.md  # Completion verification
│       ├── status.md     # Real-time state
│       └── review.md     # Post-completion assessment
├── tasks/                # Standalone work orders
│   └── T-001-slug.md
├── contracts/            # Standalone contracts
│   └── domain-contract.md
├── checklists/           # Standalone checklists
│   └── T-001.md
└── reviews/              # Standalone reviews
    └── T-001-review.md
```

For templates, naming conventions, multi-agent workflow, source of truth hierarchy, and linking rules: see `references/execution-rules.md`.
