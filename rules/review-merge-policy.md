# Review and Merge Policy

PRs are created during implementation as drafts. Review operates on existing PRs.

## Merge Gating

Before any merge:
1. **Acquire lock**: `source lib/merge-lock.sh && acquire_merge_lock` — prevents concurrent merge races.
2. **Fetch**: `git fetch origin {merge_target}` — ensure local ref is current.
3. Read contract Branch Map for declared merge target.
4. Confirm parent freshness: `git merge-base --is-ancestor origin/{merge_target} {branch}` must pass. If not, sync first.
5. **Check mergeability**: `gh pr view {pr} --json mergeable -q .mergeable` — must be `MERGEABLE`.
6. Confirm CI green (if `require_green_ci` set).
7. Confirm no unresolved MUST-fix items in review.md.
8. Use declared `merge_target`, never hardcoded.

## Merge Execution

1. `gh pr merge {pr} --squash` (never `--delete-branch` — delete separately after verification).
2. Verify: `gh pr view {pr} --json state -q .state` must be `MERGED`.
3. **Only after verified merge**: delete remote branch, close issue, update label, cleanup worktree.

**On failure**: preserve branch + worktree, report error, release lock. Never delete branch on merge failure.

## After Merge

- Remove worktree (`git worktree remove --force`), prune stale refs.
- Auto doc sync: pull working parent → read "Doc Changes Needed" → `/sync-docs` → commit.

## Review Failure

- Write explicit MUST-fix items to review.md.
- Preserve branch metadata for next iteration.
- On REVISE, inject review.md into re-dispatch prompt.
