# work-status — Check Work Item Progress

## Input

**$ARGUMENTS**: Optional work item ID (e.g., `FEAT-001`).

## Worktree Resolution

Per `rules/collab-workflow.md` § Worktree Rules. All reads from worktree (authoritative).

## Mode A: All Items (no argument)

Glob `work/items/*/`, resolve each worktree. Print table:

| ID | Title | Type | Status | Agent | Branch | Merge Target | PR | Freshness |

If no items: "No work items found. Use `/work-plan` to create one."

## Mode B: Specific Item

Detailed view: type, status, agent, branch, PR, progress (checklist), review decision, blockers. Surface `needs-sync` explicitly as preflight failure.

## Next Actions

Print per-status commands:

```
📋 다음 단계
  planned      → /work-scaffold {ID} then bash codex-run.sh {ID}
  ready-for-review → /work-verify {ID} then /work-review {ID}
  revising     → bash codex-run.sh {ID} then /work-verify then /work-review
  implementing → tail -f work/.dispatch-logs/{SLUG}.log
  blocked      → git -C {WT_PATH} status --short, then bash codex-run.sh {ID}
```

Fallback: scaffold `--claude`, verify `--claude`, impl `/work-impl`.
`{WT_PATH}` = status.md Worktree Path (절대경로).
