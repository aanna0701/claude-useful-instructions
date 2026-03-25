# Execution Artifact Templates

YAML frontmatter templates for Work Item bundle files. Read only when generating new documents.

> For rules, workflow, and naming conventions, see `execution-rules.md`.

---

## Brief Template

Filename: `brief.md` (within work item directory)

```markdown
---
title: "FEAT-NNN: [Title]"
type: brief
status: open
source: "docs/10_architecture/rfc/RFC-NNN.md"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: []
---

# FEAT-NNN: [Title]

## Objective
[1-3 sentences. What this work achieves.]

## Source
- RFC/ADR: [link]
- Contract: [link] (if applicable)

## Scope
### In-Scope
- [Item 1]
- [Item 2]

### Out-of-Scope
- [Item] — Reason: [...]

## Dependencies
- [Prerequisite work items or external dependencies]
```

---

## Contract Template

Filename: `contract.md` (within work item directory)

```markdown
---
title: "FEAT-NNN Contract"
type: contract
status: draft
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# FEAT-NNN Contract

## Interfaces

| Interface | Type | Owner | Spec |
|-----------|------|-------|------|
| [endpoint/schema/config] | [input/output/config] | [module] | [definition] |

## Boundaries

### Allowed Modifications
- [File/module/directory that may be changed]

### Forbidden Zones
- [File/module that must NOT be changed] — Reason: [...]

## Invariants
Conditions that **must never be violated**:
1. [Invariant 1]
2. [Invariant 2]

## Test Requirements
- [ ] [Test requirement 1]
- [ ] [Test requirement 2]

## Error Handling

| Error Case | Expected Behavior |
|-----------|------------------|
| [Case] | [Behavior] |
```

---

## Checklist Template

Filename: `checklist.md` (within work item directory)

```markdown
---
title: "FEAT-NNN Checklist"
type: checklist
status: open
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# FEAT-NNN Checklist

## Pre-conditions
- [ ] [Pre-condition 1]

## Verification Items
- [ ] [Item — must be Yes/No answerable]
- [ ] [Item]

## Sign-off

| Role | Name | Date | Approved |
|------|------|------|----------|
| [Role] | | | [ ] |
```

---

## Status Template

Filename: `status.md` (within work item directory)

```markdown
---
title: "FEAT-NNN Status"
type: status
updated: YYYY-MM-DD HH:MM
---

# FEAT-NNN Status

| Field | Value |
|-------|-------|
| Status | open / in-progress / blocked / review / done |
| Agent | [Claude / Codex / human] |
| Branch | [branch name] |
| Worktree | [path] (if applicable) |

## Progress
- [x] [Completed item]
- [ ] [Pending item]

## Blockers
[Blocker description, or "None"]

## Ambiguities
[Questions about contract needing clarification from Claude]

## Changed Files
- [path/to/file] — [what changed]
```

---

## Review Template

Filename: `review.md` (within work item directory)

```markdown
---
title: "FEAT-NNN Review"
type: review
status: draft
created: YYYY-MM-DD
---

# FEAT-NNN Review

## Contract Compliance

| Contract Item | Status | Notes |
|--------------|--------|-------|
| [Interface/invariant] | Pass / Fail / Partial | [Notes] |

## Deviations
[Changes from contract. "None." if none.]

## Quality
- [ ] Naming/style consistent with codebase
- [ ] No forbidden zone violations
- [ ] Tests pass and cover requirements
- [ ] No security issues introduced

## Lessons Learned
- [At least 1 lesson]

## Decision
**[ ] MERGE** / **[ ] REVISE** (list items) / **[ ] REJECT** (reason)

## Follow-up Items
- [ ] [Follow-up]
```
