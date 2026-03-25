# Execution Artifact Rules

Rules for Work Item bundles and standalone execution documents. Read before authoring.

> For YAML frontmatter templates, see `execution-templates.md`.

---

## Work Item Bundle (Primary Pattern)

A Work Item groups 5 co-located files per feature for **multi-agent coordination** (e.g., Claude designs, Codex implements, Claude reviews).

### Directory Structure

```
work/items/FEAT-NNN-slug/
  brief.md        ← What & why (scope, non-scope, design links)
  contract.md     ← Implementation boundaries (interfaces, zones, test requirements)
  checklist.md    ← Completion verification (Yes/No items)
  status.md       ← Real-time state (status, agent, branch, blockers)
  review.md       ← Post-completion assessment (compliance, lessons, merge decision)
```

### Source of Truth Hierarchy

```
RFC/ADR (why) → Contract (guarantees) → Brief (scope) → Checklist (verify) → Review (results)
```

### Multi-Agent Workflow

| Phase | Actor | Reads | Writes |
|-------|-------|-------|--------|
| 1. Design | Claude | RFC/ADR, codebase | brief + contract + checklist |
| 2. Implement | Codex | brief → contract → checklist | code + status |
| 3. Review | Claude | code + contract + checklist | review |

**Principle:** Claude designs and reviews. Codex follows the contract — never makes design decisions.

### Status Lifecycles

| Subtype | Lifecycle |
|---------|-----------|
| Brief | open → in-progress → blocked → done |
| Contract | draft → signed → superseded |
| Checklist | open → in-progress → done |
| Status | (always current — updated on every transition) |
| Review | draft → published |

### Codex Prompt Template

```
Read in order:
1. work/items/FEAT-NNN-slug/brief.md
2. work/items/FEAT-NNN-slug/contract.md
3. work/items/FEAT-NNN-slug/checklist.md

Implement only what is required.
Do not broaden scope.
If the contract is ambiguous, do not invent behavior.
Write ambiguities to work/items/FEAT-NNN-slug/status.md.
```

---

## Naming Conventions

| Item | Format | Example |
|------|--------|---------|
| Work Item ID | `FEAT-NNN` (3-digit, monotonic) | `FEAT-001` |
| Directory | `FEAT-NNN-slug/` (kebab-case) | `FEAT-001-dataset-ingest/` |
| Files within | `{brief,contract,checklist,status,review}.md` | Fixed names |

### Standalone Execution Docs

For standalone use outside work item bundles (backward compatible):

| Item | Format | Location |
|------|--------|----------|
| Task | `T-NNN-slug.md` | `work/tasks/` |
| Contract | `{domain}-contract.md` | `work/contracts/` |
| Checklist | `T-NNN.md` | `work/checklists/` |
| Review | `T-NNN-review.md` | `work/reviews/` |

> Standalone templates follow the same field structure as bundle files. Use bundles for multi-agent work; standalone for simple single-agent tasks.

---

## Linking Rules

| Document | MUST link to | Related Diataxis Doc |
|----------|-------------|---------------------|
| Brief | Source RFC/ADR or Contract | Explanation (design rationale), Reference (API spec) |
| Contract | Brief (parent) | Reference (detailed spec) |
| Checklist | Brief (parent) | How-to (operational procedures) |
| Review | Brief + Checklist | Explanation (reflect lessons learned) |

Reverse linking recommended: list derived Work Items at the bottom of RFC/ADR documents.
