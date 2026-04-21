# work-refactor — Refactor a Work Item (Cursor)

For `REFAC` only. Same pipeline as `/work-impl` but with preservation constraints.

**You are Cursor Composer/Agent running in the work item's worktree.**

> Prerequisite: Cursor opened on the worktree directory (not repo root).
> Claude Code's `/work-plan` created contract + branch + worktree + draft PR.

## Input

```
/work-refactor {ID}    # e.g. /work-refactor REFAC-007
```

## Steps

1. **Verify worktree context** (same as `/work-impl` step 1).

2. **Read contract**:
   - `work/items/{ID}-*/contract.md`
   - Pay **special attention** to `Boundaries.Preserve` — public API / behavior invariants.

3. **Check re-entry** — unresolved review threads if `reviewDecision = CHANGES_REQUESTED` (same GraphQL query as `/work-impl` step 3).

4. **Refactor** — use Composer/Agent across files, with constraints:
   - **Behavior preservation**: every existing test must stay green.
   - **API preservation**: do not modify symbols listed in `Boundaries.Preserve` unless contract explicitly allows.
   - `Touch` globs enforced. `Forbidden` globs off-limits.
   - Prefer small, mechanical commits. Run tests between commits.
   - If new tests are needed to pin down existing behavior, add them **first** (characterization tests).

5. **Commit + push** with `-s`:
   ```bash
   git add -A
   git commit -s -m "refactor({ID}): <one-line description>"
   git push
   ```
   Pre-commit hook + CI same as `/work-impl`.

6. **Resolve review threads** (same GraphQL mutation as `/work-impl` step 6).

7. **Promote draft → ready** if checks green:
   ```bash
   gh pr ready "$PR_NUMBER"
   ```

8. **Summary** — same `gh pr view` fields.

## Differences from `/work-impl`

- Must read `Boundaries.Preserve` and not violate it.
- No new features. No new public symbols unless contract says so.
- Characterization tests encouraged before behavior-preserving edits.

## Errors

Same as `/work-impl`. Additional:
- `ERROR: Preserve violation: symbol {X} modified` → revert and stop.
- `ERROR: test previously passing now fails` → revert the offending hunk.
