# Execution Artifact Rules

Rules for Work Item bundles and standalone execution documents. Read before authoring.

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

## DO / DON'T

| DO | DON'T |
|----|-------|
| Include **source link** (RFC/ADR/Contract) in brief | Create work items without a source |
| Keep **brief** concise (< 1 page) | Dump entire RFC into brief |
| **Contract** specifies boundaries explicitly | Vague "integrate well" language |
| **Checklist** items Yes/No verifiable | Subjective "is code quality good?" |
| **Status** updated on every state change | Communicate status only verbally |
| **Review** records lessons learned | Close with just "LGTM" |
| Keep Codex scoped to contract | Let Codex make design decisions |

---

## Subtype A: Brief

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

**Status lifecycle:** `open → in-progress → blocked → done`

---

## Subtype B: Contract

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

**Status lifecycle:** `draft → signed → superseded`

---

## Subtype C: Checklist

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

**Status lifecycle:** `open → in-progress → done`

---

## Subtype D: Status

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

**Update rule:** Agent updates on every state transition. Always reflects current state.

---

## Subtype E: Review

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

**Status lifecycle:** `draft → published`

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

| Document | MUST link to |
|----------|-------------|
| Brief | Source RFC/ADR or Contract |
| Contract | Brief (parent) |
| Checklist | Brief (parent) |
| Review | Brief + Checklist |

Reverse linking recommended: list derived Work Items at the bottom of RFC/ADR documents.

---

## Cross-Axis Linking

| Work Item Doc | Related Diataxis Doc |
|--------------|---------------------|
| Brief | Explanation (design rationale), Reference (API spec) |
| Contract | Reference (detailed spec) |
| Checklist | How-to (operational procedures) |
| Review | Explanation (reflect lessons learned) |

---

## Anti-Patterns

1. **Sourceless Brief** — No RFC/ADR link: no traceability for "why"
2. **LGTM Review** — No substance: no lesson accumulation
3. **Vague Contract** — No concrete boundaries: implementer makes design decisions
4. **Orphan Checklist** — Checklist remains after work item deletion: clean up periodically
5. **Design in Brief** — Alternative comparisons in Brief: separate into Explanation
6. **Stale Status** — Status not updated: other agents make wrong assumptions
7. **Scope Creep** — Implementer goes beyond contract: enforce via review
