# work-status — Check Work Item Progress

---

## Input

**$ARGUMENTS**: Optional work item ID (e.g., `FEAT-001`, `CHORE-002`).

---

## Worktree-First Resolution

Per `rules/collab-workflow.md` § Worktree-First File Resolution. All reads use worktree path (authoritative), cwd only as fallback.

## Canonical States

Report only these states:
- `planned`
- `implementing`
- `blocked`
- `ready-for-review`
- `reviewing`
- `revising`
- `merged`
- `rejected`

## Mode A: All Items (no argument)

Glob `work/items/*/` for slugs, then apply worktree-first resolution to each. Extract key fields and print:

| ID | Title | Type | Status | Agent | Branch | Merge Target | PR | Freshness |
|----|-------|------|--------|-------|--------|--------------|-----|-----------|
| FEAT-001 | User Auth | feat | implementing | Codex | feat/FEAT-001-user-auth | research | #51 (draft) | fresh |
| CHORE-002 | Dep Upgrade | chore | planned | TBD | — | main | — | — |

If `.claude/branch-map.yaml` exists, populate Merge Target and check freshness per `rules/branch-map-policy.md`. If no items: "No work items found. Use `/work-plan` to create one."

## Mode B: Specific Item

Apply worktree-first resolution, then read status.md and checklist.md (parallel; also review.md if exists).

```
{ID}: [Title]
Type:       feat | fix | docs | chore | refactor | test | perf
Status:     planned | implementing | blocked | ready-for-review | reviewing | revising | merged | rejected
Agent:      Codex
Branch:     feat/FEAT-NNN-slug
PR:         #51 (draft)
Progress:   7/10 checklist items
  [x] Item 1
  [ ] Item 3 (pending)
Review:     REVISE (2 items remaining)   ← only if review.md exists
Issue:      needs-sync                    ← if blocked by runner/Codex preflight
Blockers:   Runner auto-sync from parent branch failed...
```

If `Status=blocked` and `Issue=needs-sync`, surface that explicitly as a branch/dependency preflight failure, not a coding failure.

## Always: Next Actions

Print actionable commands based on each item's status. Only print sections with matching items:

```
Next Actions
──────────────────────────────────────────────
# planned → dispatch
  bash codex-run.sh {ID}
  /work-impl {ID}

# ready-for-review → review
  /work-review {ID}

# revising → re-dispatch
  /work-revise {ID}

# implementing → check logs
  tail -f work/.dispatch-logs/{SLUG}.log

# blocked + needs-sync → sync and rerun
  git -C <worktree_path> status --short
  git -C <worktree_path> branch --show-current
  bash codex-run.sh {ID}
  # if rerun blocks again, inspect status.md Blockers and resolve merge/dependency issue first
──────────────────────────────────────────────
```

Resolve `<worktree_path>` from each item's status.md for codex exec commands.
