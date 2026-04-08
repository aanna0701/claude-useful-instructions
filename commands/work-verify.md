# work-verify — Verify Implementation Against Contract

Verify implementation against contract and write results, optionally with Cursor integration.

## Input

```
/work-verify FEAT-001                      # 검증 + Cursor 프롬프트
/work-verify FEAT-001 --claude             # 검증 only (no Cursor)
/work-verify AUDIT-003                     # AUDIT: this IS the execution step
```

## Steps

1. **Resolve**: Per `rules/collab-workflow.md` § Work Item Discovery (searches cwd, worktrees, sibling dirs), locate `work/items/{ID}-*/`. Read `status.md`, resolve worktree per § Worktree Resolution
2. **Read relay**: Per `rules/collab-workflow.md` § Relay Protocol — read `relay.md` for impl results. If impl `result: blocked`, abort with error. Use `changed` files list to scope verification.
3. **Verify** (always — both modes): Read code in worktree, verify against contract (boundaries, interfaces, invariants, test requirements, checklist). Write `verify-result.md` in worktree.
4. **Relay**: Append `verify` block to `relay.md` with passed/failed counts and failure details. Post PR comment.
5. **Cursor integration** (default mode only, skip with `--claude`): Also generate Cursor Composer prompt for manual re-verification
6. **Update status**: AUDIT/DOCS → `auditing`. FEAT/REFAC/FIX → unchanged.
7. **Output**: Print verification summary. Default mode: also print Composer prompt with absolute `{WT_PATH}`

## Verification Items

**FEAT/REFAC/FIX**: Boundaries, interfaces, invariants, test requirements, error handling, checklist.

**AUDIT/DOCS**: Audit scope + criteria from contract. Findings table with severity (CRITICAL/HIGH/MEDIUM/LOW).

**MANDATORY NEXT-STEP TEMPLATE** — Print the block below as-is. Fill `«___»` slots with actual ID. Do NOT add, remove, or reorder lines.

```
📋 다음 단계
  /work-review «ID»                        # FEAT/REFAC/FIX
  /work-plan --type=fix "Fix «ID»"         # AUDIT (선택)
```

## Error Handling

- Missing work item or contract: `ERROR`
- Wrong status: `WARN: proceeding anyway`
- Missing worktree: `WARN: prompt without worktree context`
