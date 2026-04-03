# work-revise — Re-dispatch REVISE Items

---

## Input

**$ARGUMENTS**: Work item IDs (e.g., `FIX-003`) or glob.

No arguments: auto-glob items with REVISE decision in review.md. If none: "No items pending revision."

---

## Execution

Per `rules/collab-workflow.md` § Worktree-First File Resolution, read review.md and status.md from worktree (authoritative).

Resolve IDs to items with REVISE decision. Spawn `work-reviser` agent per item (parallel). Each agent extracts MUST-fix items, updates status to `revising`, and re-dispatches.

State transition rules:
- `reviewing -> revising`
- `revising -> implementing` only when re-dispatch begins
- keep the same feature branch and worktree
- never create a second worktree for the same item

## Summary

```
Revision Dispatched
──────────────────────────────────────────────
  FIX-003   null-pointer       3 MUST-fix  → codex     #44 open
  REFAC-005 cache-invalidation 1 MUST-fix  → agent     #46 open
──────────────────────────────────────────────

# Dispatch:
  bash codex-run.sh FIX-003 REFAC-005
  /work-impl FIX-003

# After completion:
  /work-review FIX-003 REFAC-005
```
