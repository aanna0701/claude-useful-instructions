# work-verify — Verify Implementation Against Contract

Generate a Cursor verification prompt, or execute directly with `--claude`.

## Input

```
/work-verify FEAT-001                      # Cursor 프롬프트 생성
/work-verify FEAT-001 --claude             # Claude가 직접 검증
/work-verify AUDIT-003                     # AUDIT: this IS the execution step
```

## Steps

1. **Resolve**: Locate `work/items/{ID}-*/`, read `status.md`, resolve worktree per `rules/collab-workflow.md` § Worktree Rules
2. **Read relay**: Per `rules/collab-workflow.md` § Relay Protocol — read `relay.md` for impl results. If impl `result: blocked`, abort with error. Use `changed` files list to scope verification.
3. **Generate**:
   - **Default**: Spawn `cursor-prompt-builder` agent. Prompt instructs Cursor to write `verify-result.md` in worktree.
   - **`--claude`**: Read code directly, verify against contract, write `verify-result.md`.
4. **Relay**: Append `verify` block to `relay.md` with passed/failed counts and failure details. Post PR comment.
5. **Update status**: AUDIT/DOCS → `auditing`. FEAT/REFAC/FIX → unchanged.
6. **Output**: Print prompt with absolute `{WT_PATH}`

## Verification Items

**FEAT/REFAC/FIX**: Boundaries, interfaces, invariants, test requirements, error handling, checklist.

**AUDIT/DOCS**: Audit scope + criteria from contract. Findings table with severity (CRITICAL/HIGH/MEDIUM/LOW).

**MANDATORY OUTPUT**: The `📋 다음 단계` block below MUST appear verbatim in the final response, including when executed by a subagent.

```
📋 다음 단계
  /work-review {ID}                        # FEAT/REFAC/FIX
  /work-plan --type=fix "Fix {ID}"         # AUDIT (선택)
```

## Error Handling

- Missing work item or contract: `ERROR`
- Wrong status: `WARN: proceeding anyway`
- Missing worktree: `WARN: prompt without worktree context`
