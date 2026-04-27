# work-impl — Implement a Work Item (Local-Only)

For `FEAT / FIX / PERF / CHORE / TEST`. No PR, no CI — review is a local file.

## Input

```
/work-impl {ID}        # e.g. /work-impl FEAT-042
```

## Steps

1. **Resolve worktree** by branch convention:
   ```bash
   BRANCH=$(git branch --list "feature-*-${slug}" | head -1)
   WT_PATH=$(git worktree list --porcelain \
     | awk -v b="$BRANCH" '$1=="worktree"{p=$2} $1=="branch" && $2=="refs/heads/"b{print p}')
   ```
   If unresolved → `ERROR: worktree for {ID} not found. Run /work-plan or check git worktree list.`
2. **Read inputs** from worktree:
   - `$WT_PATH/.work/contracts/{ID}-{slug}/contract.md`
3. **Check re-entry** — look for the latest review file:
   ```bash
   ls -t "$WT_PATH/.work/contracts/{ID}-{slug}/"review-*.md 2>/dev/null | head -1
   ```
   If a review file exists with status `CHANGES_REQUESTED`, treat its **MUST-fix** items as the punch list.
4. **Implement** in `$WT_PATH`:
   - Honor `contract.Boundaries.Touch` / `Forbidden`.
   - On re-entry, address every MUST-fix item in the latest review file.
   - Keep tests green between commits. Small commits.
5. **Commit** (`-s` required for DCO):
   ```bash
   cd "$WT_PATH"
   git add -A
   git commit -s -m "{type}({ID}): <description>"
   ```
   Pre-commit runs ruff + mypy + pyright + clang-format locally. There is no CI.
6. **Optional push** for backup/sync (no PR):
   ```bash
   git push 2>/dev/null || true
   ```
7. **Mark review-ready** — touch a sentinel that `/work-review` can detect:
   ```bash
   : > "$WT_PATH/.work/contracts/{ID}-{slug}/.ready"
   ```
8. **Summary** — print branch, worktree path, and `git log --oneline $PARENT..HEAD`.

## Output

- Branch + worktree path
- Commits added since parent
- `Next: /work-review {ID}`

## Errors

- `git` failure → raise, no fallback.
- Worktree not found → direct to `/work-plan`.
- Contract touches outside `Touch` globs → stop, report violation.
