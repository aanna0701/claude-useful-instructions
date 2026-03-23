# Execution Artifact Rules

Rules for agents writing execution documents (task, contract, checklist, review). Read before authoring.

---

## Identity

Execution Artifacts = documents for **Delivery Control** (assigning, tracking, verifying work).
They are orthogonal to Diataxis docs (reader-facing knowledge).

> For the full dual-axis model definition, see `references/common-rules.md` Section 4-1.

### Source of Truth Hierarchy

```
RFC/ADR (why) → Contract (guarantees) → Task (what to do) → Checklist (how to verify) → Review (results)
```

The source of truth is **RFC/ADR + Contract**. Tasks are derived work orders.

---

## DO / DON'T

| DO | DON'T |
|----|-------|
| Include **source link** (RFC/ADR/Contract) | Create Tasks without a source |
| Specify **acceptance criteria** concretely | Vague criteria like "works well" |
| Update **status** lifecycle honestly | Neglect status, communicate only verbally |
| Checklist items must be **Yes/No verifiable** | Subjective items like "is code quality good?" |
| Record **lessons learned** in Reviews | Close with just "LGTM" |
| State **invariants** in Contracts | Ambiguous "try to maintain" language |

---

## Physical Structure

See `references/site-architecture.md` Section 7 for directory structure.

---

## Subtype A: Task Template

Filename: `T-NNN-slug.md` (e.g., `T-001-dataset-ingest.md`)

```markdown
---
title: "T-NNN: [Task Title]"
type: task
status: open
source: "docs/10_architecture/rfc/RFC-NNN.md"
assignee: "@handle"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: []
---

# T-NNN: [Task Title]

## Objective

[What this task achieves. 1-3 sentences.]

## Source

- RFC/ADR: [link]
- Contract: [link] (if applicable)

## Scope

### In-Scope
- [Item 1]
- [Item 2]

### Out-of-Scope
- [Item] — Reason: [...]

## Acceptance Criteria

- [ ] [Verifiable criterion 1]
- [ ] [Verifiable criterion 2]
- [ ] [Verifiable criterion 3]

## Dependencies

- [Prerequisite tasks or external dependencies]

## Notes

[Additional context, references]
```

**Status lifecycle:** `open → in-progress → blocked → in-progress → done`

---

## Subtype B: Contract Template

Filename: `{domain}-contract.md` (e.g., `dataset-schema-contract.md`)

```markdown
---
title: "[Domain] Contract"
type: contract
status: draft
author: "@handle"
owner: "@handle"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: []
---

# [Domain] Contract

## Parties

| Party | Role | Responsibility |
|-------|------|----------------|
| [Module/Team A] | Provider | [What they provide] |
| [Module/Team B] | Consumer | [What they consume] |

## Specification

### Schema / API Surface

[Concrete schema, API endpoints, data format definitions]

### SLA (if applicable)

| Metric | Target | Measurement |
|--------|--------|-------------|
| [Metric] | [Target] | [Method] |

## Invariants

Conditions that **must never be violated** while this contract holds:

1. [Invariant 1]
2. [Invariant 2]

## Violation Handling

| Violation | Detection | Response |
|-----------|-----------|----------|
| [Type] | [Method] | [Procedure] |

## Versioning

- Current version: v1
- On breaking change: create new Contract file + mark existing as `superseded`
```

**Status lifecycle:** `draft → review → signed → superseded`

---

## Subtype C: Checklist Template

Filename: `T-NNN.md` (matches Task ID)

```markdown
---
title: "Checklist: T-NNN"
type: checklist
status: open
task_id: "T-NNN"
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Checklist: T-NNN — [Task Title]

## Task Reference

- Task: [planning/tasks/T-NNN-slug.md](../tasks/T-NNN-slug.md)

## Pre-conditions

- [ ] [Pre-condition 1]
- [ ] [Pre-condition 2]

## Verification Items

- [ ] [Item 1 — must be Yes/No answerable]
- [ ] [Item 2]
- [ ] [Item 3]

## Sign-off

| Role | Name | Date | Approved |
|------|------|------|----------|
| [Role] | [@handle] | | [ ] |
```

**Status lifecycle:** `open → in-progress → done`

---

## Subtype D: Review Template

Filename: `T-NNN-review.md`

```markdown
---
title: "Review: T-NNN"
type: review
status: draft
task_id: "T-NNN"
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Review: T-NNN — [Task Title]

## Task Reference

- Task: [planning/tasks/T-NNN-slug.md](../tasks/T-NNN-slug.md)
- Checklist: [planning/checklists/T-NNN.md](../checklists/T-NNN.md)

## Deliverables

| Deliverable | Status | Notes |
|-------------|--------|-------|
| [Item 1] | Done / Partial / Skipped | [Notes] |

## Deviations from Plan

[Changes from the original plan. "None." if none.]

## Lessons Learned

- [Lesson 1]
- [Lesson 2]

## Follow-up Items

- [ ] [Follow-up 1]
- [ ] [Follow-up 2]
```

**Status lifecycle:** `draft → published`

---

## Naming Conventions

| Item | Format | Example |
|------|--------|---------|
| Task ID | `T-NNN` (3-digit, monotonic) | `T-001`, `T-042` |
| Task file | `T-NNN-slug.md` (kebab-case) | `T-001-dataset-ingest.md` |
| Contract file | `{domain}-contract.md` | `dataset-schema-contract.md` |
| Checklist file | `T-NNN.md` | `T-001.md` |
| Review file | `T-NNN-review.md` | `T-001-review.md` |

---

## Linking Rules

| Document | MUST link to |
|----------|-------------|
| Task | Source RFC/ADR or Contract |
| Checklist | Parent Task |
| Review | Parent Task + Checklist |
| Contract | Independent OK; link RFC/ADR if related |

Reverse linking recommended: list derived Tasks at the bottom of RFC/ADR documents.

---

## Cross-Axis Linking

| Execution Doc | Related Diataxis Doc |
|--------------|---------------------|
| Task | Explanation (design rationale), Reference (API spec) |
| Contract | Reference (detailed spec) |
| Checklist | How-to (operational procedures) |
| Review | Explanation (reflect lessons learned) |

---

## Anti-Patterns

1. **Sourceless Task** — Task without RFC/ADR or Contract: no traceability for "why"
2. **LGTM Review** — Review with no substance: no lesson accumulation
3. **Vague Contract** — No concrete schema, just "integrate well": invariants unverifiable
4. **Orphan Checklist** — Checklist remains after Task deletion: clean up periodically
5. **Design in Task** — Alternative comparisons in a Task: separate into Explanation
