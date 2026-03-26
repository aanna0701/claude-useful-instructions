# Documentation Site Architecture (Information Architecture)

Defines the **hierarchy, numbering scheme, and governance rules** for MkDocs-based documentation sites.
`/init-docs` command initializes project docs according to these rules.

---

## 1. 3-Level Folder Hierarchy

The `00-99` numbering scheme enforces sort order. Numbers represent **topic categories**;
each category contains multiple Diataxis types (Guide / Explanation / Reference) organized by topic.

```
docs/
├── index.md                         # Doc home (project overview + workflow map)
├── glossary.md                      # Glossary (SSOT)
│
├── 00_context/                      # Context: why this project
│   ├── index.md
│   ├── business-goals.md            # [Explanation]
│   ├── personas.md                  # [Reference]
│   └── requirements.md              # [Reference]
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
├── 30_guides/                       # Guides: practical work (by workflow)
│   ├── index.md                     # Workflow map
│   ├── auth/                        # Auth workflow
│   │   ├── getting-started.md       # [Guide: beginner]
│   │   └── add-oauth-provider.md    # [Guide: practitioner]
│   ├── deploy/                      # Deploy workflow
│   │   ├── first-deploy.md          # [Guide: beginner]
│   │   └── rollback.md              # [Guide: practitioner]
│   └── data/                        # Data workflow
│       ├── first-migration.md       # [Guide: beginner]
│       └── zero-downtime-migration.md # [Guide: practitioner]
│
├── 40_operations/                   # Operations: production management
│   ├── index.md
│   ├── monitoring.md                # [Explanation]
│   ├── runbook.md                   # [Guide: practitioner]
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
| `30` | Guides | **How** to use it? (practical, by workflow) |
| `40` | Operations | **How** to run it? (production) |
| `50-80` | (Reserved) | Project-specific extensions |
| `90` | Archive | Deprecated documents |

### Numbering vs Diataxis Mapping

Numbering = **topic (domain)** classification. Diataxis = **purpose** classification. They are orthogonal.

```
              Guide      Explanation   Reference
00_context       -          ●            ●
10_architecture  -          ●            ●
20_implementation-          ●            ●
30_guides        ●          -            -
40_operations    ●          ●            ●
```

Diataxis type is specified via the `type` field in YAML frontmatter. Guide level via `level` field.

### Guide Workflow Organization

Guides in `30_guides/` are organized by **workflow topic**, not by level or document type.

Each workflow subfolder contains beginner and practitioner guides for one domain:
- Beginner guides are prerequisites for practitioner guides in the same workflow
- All guides link to relevant Reference and Explanation docs
- `30_guides/index.md` contains the **workflow map** — a table listing all workflows with links to their guides, references, and explanations

---

## 2. MkDocs Configuration

**Theme:** `material` with navigation tabs/sections/indexes, search suggest/highlight, TOC integration, light/dark toggle.

**Required plugins:** `search`, `tags`, `git-revision-date-localized` (with `enable_creation_date: true`).

**Required extensions:** `admonition`, `pymdownx.details`, `pymdownx.superfences` (with mermaid fence), `pymdownx.tabbed`, `attr_list`, `md_in_html`, `toc` (with permalink).

**Tags:** Define allowed tags in `extra.tags` (e.g., `auth`, `database`, `api`, `infra`, `security`).

**Nav structure** mirrors the numbered folder hierarchy: Home, Glossary, Context, Architecture (with ADR sub-section), Implementation, Guides (by workflow), Operations, Archive.

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

### Guides Workflow Map Template (`30_guides/index.md`)

```markdown
---
title: "Guides"
tags: []
---

# Guides

Step-by-step procedures organized by workflow.

## Workflows

| Workflow | Beginner Guide | Practitioner Guide | Reference | Explanation |
|----------|---------------|-------------------|-----------|-------------|
| Auth | [Getting Started](auth/getting-started.md) | [Add OAuth](auth/add-oauth-provider.md) | [Auth API](../20_implementation/auth-api.md) | [Auth Strategy](../10_architecture/adr/002-auth-strategy.md) |
| Deploy | [First Deploy](deploy/first-deploy.md) | [Rollback](deploy/rollback.md) | [CI/CD Config](../20_implementation/cicd-config.md) | [Deploy Overview](../10_architecture/deploy-overview.md) |
```

---

## 3. Five Governance Rules

### Rule 1: Single Source of Truth (SSOT) — Write Once, Link Everywhere

Same information exists in **exactly one place**. This is the most critical rule.

| Pattern | DO | DON'T |
|---------|-----|-------|
| API spec | Auto-generate from code, link from design docs | Copy-paste spec into design docs |
| Config values | One config reference file | Duplicate in README + guides |
| Term definitions | Define in `glossary.md`, link elsewhere | Redefine in each document |
| Setup steps | Write in one beginner guide, link from others | Repeat in every guide |
| Parameter tables | Write in Reference, link from Guides | Copy tables into Guides |

**Violation test:** If the same info exists in 2+ places, designate one as canonical and replace others with links.

**DRY Enforcement for Guides:**
- Guide needs parameter details → link to Reference doc
- Guide needs architecture context → link to Explanation doc
- Practitioner guide needs setup → link to beginner guide as prerequisite
- Multiple guides share a common step → extract to a shared guide, link from others

### Rule 2: Date & Status

Required frontmatter: `title`, `type`, `status`, `author`, `owner`, `created`, `updated`, `tags`, `audience`.
For Guides: also `level` (`beginner` | `practitioner`) and `workflow` (workflow name).
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
