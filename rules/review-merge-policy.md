# Review and Merge Policy (Local-Only)

Reviews are local markdown files inside `.work/contracts/{ID}-{slug}/`. Merge is a local `git merge --squash` performed by `/work-review` on APPROVE.

## Merge Gating

Before any merge:
1. **Acquire lock**: `source lib/merge-lock.sh && acquire_merge_lock` — prevents concurrent merge races.
2. **Worktree clean**: `git -C $WT_PATH diff --quiet && git -C $WT_PATH diff --cached --quiet`.
3. **Parent fresh** on the main worktree: `git rev-parse $PARENT` must succeed; if a remote exists, `git fetch origin $PARENT` first.
4. **Pre-commit clean** on the diff range: `pre-commit run --from-ref $PARENT --to-ref HEAD`.
5. **No unresolved MUST-fix** in any prior `review-*.md` for the current HEAD SHA.

## Merge Execution

1. Switch the **main worktree** to the parent branch.
2. `git merge --squash $BRANCH`
3. `git commit -s -m "<subject> ({ID})"`
4. Optional `git push` (only when `origin` exists and the user keeps a remote mirror).
5. **Delete the contract directory** — `rm -rf .work/contracts/{ID}-{slug}/`. This is the "PR close" step and the canonical signal that the work item is done.

The `worktree-cleanup` PostToolUse hook fires on `git merge`, removes the worktree, the local branch, and the remote branch (if any), and double-checks the contract directory deletion.

**On failure**: preserve branch + worktree + contract dir, report error, release lock. Never delete the contract directory on merge failure.

## After Merge

- Worktree removal + branch deletion handled by `worktree-cleanup` hook.
- Auto doc sync (optional): on the parent branch, run `/sync-docs` and commit.

## Review Failure

- Write the new `review-{shortSHA}.md` with `Status: CHANGES_REQUESTED` and the MUST-fix list.
- Preserve branch + worktree + contract dir for the next iteration.
- On re-entry, `/work-impl` and `/work-refactor` read the latest `review-*.md` as their punch list.
