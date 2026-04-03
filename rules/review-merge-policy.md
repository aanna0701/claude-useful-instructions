# Review and Merge Policy

PRs are created during implementation as drafts. Review operates on existing PRs.

## Merge Gating

Before any merge:
1. Read contract Branch Map for declared merge target.
2. Confirm parent freshness — branch must include all parent commits.
3. Confirm CI green (if `require_green_ci` set).
4. Confirm no unresolved MUST-fix items in review.md.
5. Use declared `merge_target`, never hardcoded.

## After Merge

Per `merge_policy` in branch-map.yaml:
- Confirm with user if `ask_confirm_before_merge` is true (check **before** merge).
- Delete branch if `delete_branch_after_merge` is true.
- Remove worktree, prune stale refs.
- Auto doc sync: pull working parent → read "Doc Changes Needed" → `/sync-docs` → commit.

## Review Failure

- Write explicit MUST-fix items to review.md.
- Preserve branch metadata for next iteration.
- On REVISE, inject review.md into re-dispatch prompt.
