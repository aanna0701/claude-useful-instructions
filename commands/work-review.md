# work-review — Review a Work Item (Local-Only)

Read the local diff + contract, write a review file, and on APPROVE merge locally and delete the contract directory ("PR close").

## Input

```
/work-review {ID}      # e.g. /work-review FEAT-042
```

## Steps

1. **Resolve worktree + branch + parent**:
   ```bash
   BRANCH=$(git branch --list "feature-*-${slug}" | head -1)
   WT_PATH=$(git worktree list --porcelain \
     | awk -v b="$BRANCH" '$1=="worktree"{p=$2} $1=="branch" && $2=="refs/heads/"b{print p}')
   PARENT=$(cat "$WT_PATH/.claude-worktree-meta" 2>/dev/null | jq -r .base_branch \
     || git rev-parse --abbrev-ref "$BRANCH@{upstream}" 2>/dev/null \
     || echo "feature-init-dev")
   HEAD_SHA=$(git -C "$WT_PATH" rev-parse HEAD)
   SHORT=${HEAD_SHA:0:7}
   ```
2. **Read inputs**:
   - `$WT_PATH/.work/contracts/{ID}-{slug}/contract.md`
   - Diff: `git -C "$WT_PATH" diff "$PARENT"...HEAD`
   - Commits: `git -C "$WT_PATH" log --oneline "$PARENT"..HEAD`
3. **Evaluate** against contract:
   - Boundaries respected (Touch / Forbidden / Preserve)?
   - Acceptance criteria satisfied?
   - Pre-commit (ruff/mypy/pyright/clang-format) ran clean? Re-run if uncertain: `cd "$WT_PATH" && pre-commit run --from-ref "$PARENT" --to-ref HEAD`.
   - Code quality (readability, error handling, tests cover acceptance)?
4. **Classify findings**:
   - **MUST-fix** → block merge.
   - **SHOULD / NICE** → advisory only.
5. **Write review file** to `.work/contracts/{ID}-{slug}/review-${SHORT}.md`:
   ```markdown
   # Review {ID} @ {SHORT}

   **Status**: APPROVED | CHANGES_REQUESTED
   **Reviewer**: claude-code
   **Reviewed at**: <ISO timestamp>

   ## Summary
   <one paragraph>

   ## MUST-fix
   - [ ] `path/to/file.py:42` — <comment>

   ## SHOULD
   - <comment>

   ## NICE
   - <comment>
   ```
   Write to **both** the main repo's `.work/` and the worktree's `.work/` so subsequent `/work-impl` re-entries can read it.
6. **If `CHANGES_REQUESTED`** — stop here. Print review file path. Next step: user runs `/work-impl {ID}` or `/work-refactor {ID}` again.
7. **If `APPROVED`** — local merge + cleanup:
   1. Acquire lock: `source lib/merge-lock.sh && acquire_merge_lock || { echo "skip: merge lock busy"; exit 0; }`
   2. Preconditions (all must hold — else `release_merge_lock` and skip with reason):
      - Worktree clean: `git -C "$WT_PATH" diff --quiet && git -C "$WT_PATH" diff --cached --quiet`
      - Parent fresh on the main worktree: `git -C "$REPO_ROOT" rev-parse "$PARENT" >/dev/null`
      - Pre-commit green on the diff range
      - No unresolved MUST-fix items in any prior `review-*.md`
   3. Squash-merge into parent **on the main worktree**:
      ```bash
      git -C "$REPO_ROOT" switch "$PARENT"
      git -C "$REPO_ROOT" merge --squash "$BRANCH"
      git -C "$REPO_ROOT" commit -s -m "$(git -C "$WT_PATH" log -1 --format=%s) ({ID})"
      ```
   4. Optional push (only if origin exists and you sync):
      ```bash
      git -C "$REPO_ROOT" push 2>/dev/null || true
      ```
   5. **Archive the contract directory** — this is the "PR close" step. The directory is *moved* (not deleted), with the archive epoch encoded in the destination name so no sidecar file is needed. A follow-up implementation can crib from the previous spec/review until the `worktree-cleanup` hook purges archives older than `WORK_ARCHIVE_TTL_DAYS` (default 7):
      ```bash
      mkdir -p "$REPO_ROOT/.work/archive"
      TS=$(date +%s)
      mv "$REPO_ROOT/.work/contracts/{ID}-{slug}" "$REPO_ROOT/.work/archive/{ID}-{slug}.archived-${TS}"
      ```
   6. Worktree + branch + remote-branch cleanup (and a fallback archive sweep) is handled automatically by the `worktree-cleanup` PostToolUse hook (it fires on `git merge`). No manual step required.
   7. `release_merge_lock`.
8. **Output** — review file path + decision + count of MUST-fix / SHOULD + (on APPROVE) merge commit SHA + cleanup result.

## After review

- `CHANGES_REQUESTED` → user runs `/work-impl {ID}` or `/work-refactor {ID}` again. New commits land on the same branch; re-run `/work-review` (it writes a fresh `review-{newSHA}.md`).
- `APPROVED` + preconditions met → `/work-review` squash-merges locally, archives the contract directory under `.work/archive/` (kept for `WORK_ARCHIVE_TTL_DAYS` days, default 7, then purged), and the `worktree-cleanup` hook removes the feature worktree + branch.
- `APPROVED` + merge skipped (worktree dirty, MUST-fix outstanding, lock busy) → review file is written. User resolves the skip reason, then re-runs `/work-review`.

## Errors

- `git` failure → raise, no fallback.
- Worktree not found → `ERROR: no worktree on head feature-*-${slug}`.
- Contract directory missing → `ERROR: .work/contracts/{ID}-{slug}/ not found; run /work-plan first`.
