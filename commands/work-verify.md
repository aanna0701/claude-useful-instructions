# work-verify — Verify Implementation Against Contract

Verify implementation against contract and write results, optionally with Cursor integration.

## Input

```
/work-verify FEAT-001                      # 검증 + Cursor 프롬프트
/work-verify FEAT-001 --claude             # 검증 only (no Cursor)
/work-verify AUDIT-003                     # AUDIT: this IS the execution step
```

## CRITICAL: Worktree-First Gate

**Before reading ANY work item file**, you MUST resolve the worktree path. The cwd copy of `status.md` is a stale seed — it does NOT reflect Codex/agent progress.

❌ WRONG: `Read work/items/FEAT-001-foo/status.md` (cwd — stale, shows `open` even when done)
✅ RIGHT: Resolve worktree path FIRST → `Read /abs/path/to/worktree/work/items/FEAT-001-foo/status.md`

## Steps

1. **Resolve**: Per `rules/collab-workflow.md` § Work Item Discovery (searches cwd, worktrees, sibling dirs), locate `work/items/{ID}-*/`. Resolve worktree per § Worktree Resolution. **Gate: do NOT read `status.md` or any artifact until `$WT_PATH` is resolved and validated (`$WT_PATH ≠ repo root`).** Then read from `$WT_PATH/work/items/{SLUG}/`.
2. **Read relay**: Per `rules/collab-workflow.md` § Read Before Act — use MCP `get_pull_request_comments` to read impl results (filter `<!-- relay:impl: -->`). Fallback: read `relay.md`. If impl `result: blocked`, abort with error. Use `changed` files list to scope verification.
3. **Verify** (always — both modes): Read code in worktree, verify against contract (boundaries, interfaces, invariants, test requirements, checklist). Write `verify-result.md` in worktree.
4. **Relay**: Append `verify` block to `relay.md` with passed/failed counts and failure details.
   - **PR Comment Relay**: Use MCP `add_issue_comment` to post relay comment with `<!-- relay:verify:{timestamp} -->` marker (per § PR Comment Relay). Fallback: `gh pr comment`.
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
