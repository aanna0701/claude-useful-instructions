# work-status — Check Work Item Progress

---

## Input

**$ARGUMENTS**: Optional work item ID (e.g., `FEAT-001`, `CHORE-002`).

---

## Worktree-First Resolution (applies to ALL modes)

Per `rules/collab-workflow.md` § Worktree-First File Resolution:

For each work item, resolve the **authoritative** status.md:
1. Glob `work/items/FEAT-NNN-*/` to get slug
2. Discover worktree path: `work/dispatch.json` → cwd `status.md` Worktree Path field → convention `../${PROJECT}-${SLUG}/`
3. If worktree exists: read `${WORKTREE}/work/items/${SLUG}/status.md` (authoritative)
4. Fallback to cwd copy only if worktree does not exist

**Why**: Codex updates status.md in the worktree. The main repo copy is a stale seed.

## Mode A: All Items (no argument)

Glob `work/items/*/` for slugs, then apply worktree-first resolution to each. Extract key fields and print:

| ID | Title | Type | Status | Agent | Branch | Merge Target | PR | Freshness |
|----|-------|------|--------|-------|--------|--------------|-----|-----------|
| FEAT-001 | User Auth | feat | in-progress | Codex | feat/FEAT-001-user-auth | research | #51 (draft) | fresh |
| CHORE-002 | Dep Upgrade | chore | open | TBD | — | main | — | — |

If `.claude/branch-map.yaml` exists, populate Merge Target and check freshness per `rules/branch-map-policy.md`. If no items: "No work items found. Use `/work-plan` to create one."

## Mode B: Specific Item

Apply worktree-first resolution, then read status.md and checklist.md (parallel; also review.md if exists).

```
{ID}: [Title]
Type:       feat | fix | docs | chore | refactor | test | perf
Status:     in-progress | blocked
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
# open → dispatch
  bash codex-run.sh {ID}
  /work-impl {ID}

# done → review
  /work-review {ID}

# revision → re-dispatch
  /work-revise {ID}

# in-progress → check logs
  tail -f work/.dispatch-logs/{SLUG}.log

# blocked + needs-sync → sync and rerun
  git -C <worktree_path> status --short
  git -C <worktree_path> branch --show-current
  bash codex-run.sh {ID}
  # if rerun blocks again, inspect status.md Blockers and resolve merge/dependency issue first
──────────────────────────────────────────────
```

Resolve `<worktree_path>` from each item's status.md for codex exec commands.
