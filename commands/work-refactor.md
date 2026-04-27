# work-refactor — Refactor a Work Item (Local-Only)

For `REFAC` only. Same pipeline as `/work-impl` but with preservation constraints.

## Input

```
/work-refactor {ID}    # e.g. /work-refactor REFAC-007
```

## Steps

1. **Resolve worktree** (same as `/work-impl` step 1).
2. **Read inputs** from worktree:
   - `$WT_PATH/.work/contracts/{ID}-{slug}/contract.md` — pay attention to `Boundaries.Preserve`.
3. **Check re-entry** — read the latest `review-*.md` file in the contract directory; treat MUST-fix items as the punch list.
4. **Refactor** in `$WT_PATH`:
   - **Behavior preservation**: every existing test must stay green.
   - **API preservation**: do not modify symbols listed in `Boundaries.Preserve` unless contract explicitly allows.
   - Touch globs enforced. Forbidden globs off-limits.
   - Prefer small, mechanical commits. Run tests between commits.
   - If new tests are needed to pin down existing behavior, add them first (characterization tests).
5. **Commit** with `-s`:
   ```bash
   git commit -s -m "refactor({ID}): <description>"
   ```
6. **Optional push** for backup/sync (no PR):
   ```bash
   git push 2>/dev/null || true
   ```
7. **Mark review-ready**:
   ```bash
   : > "$WT_PATH/.work/contracts/{ID}-{slug}/.ready"
   ```

## Differences from `/work-impl`

- Must read `Boundaries.Preserve` and not violate it.
- No new features. No new public symbols unless contract says so.
- Characterization tests are encouraged before behavior-preserving edits.

## Errors

Same as `/work-impl`. Additional: `ERROR: Preserve violation: symbol {X} modified` → revert and stop.
