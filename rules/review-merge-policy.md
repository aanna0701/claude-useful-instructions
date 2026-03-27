# Review and Merge Policy

PRs are created during implementation (`/work-impl` or `codex-run.sh`) as drafts.
Review operates on existing PRs — it does not create them (unless none exists as a fallback).

## Merge Gating

Before any merge:
1. Read work item metadata (contract Branch Map section) for declared merge target.
2. Confirm parent freshness — branch must include all parent commits.
3. Confirm required CI checks are green (if `require_green_ci` is set in branch-map.yaml).
4. Confirm no unresolved MUST-fix items remain in review.md.
5. Use declared `merge_target`, never a hardcoded branch name.

## After Merge

- Ask user confirmation if `ask_confirm_before_merge` is true (check **before** merge, not after).
- Delete feature branch only if `delete_branch_after_merge` is true.
- Remove worktree via `git worktree remove` (per `rules/collab-workflow.md` Worktree Convention).
- If design/contract changes were made, check whether sibling open work items need sync.
- **Auto doc sync**: `git pull` working parent → read "Doc Changes Needed" from status.md → run `/sync-docs` → commit and push. This is automatic and requires no user prompt.

## Review Failure

- Write explicit MUST-fix items to review.md.
- Preserve branch metadata for the next iteration.
- On REVISE, inject review.md into re-dispatch prompt.
