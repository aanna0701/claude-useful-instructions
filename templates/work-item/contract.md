---
title: "FEAT-NNN Contract"
type: contract
status: draft
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# FEAT-NNN Contract

## Branch Map

| Field | Value |
|-------|-------|
| Role | [docs/backend/frontend/infra/cross-cutting] |
| Parent Branch | [from branch-map.yaml working_parent] |
| Merge Target | [same as parent branch unless overridden] |
| Target Worktree | [worktree name if using worktrees, else —] |
| CI Scope | [lint, typecheck, test — inferred from affected paths] |

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
