# work-scaffold — Scaffold File Structures from Contracts

Create stub files and test skeletons from contract, optionally with Cursor integration.

## Input

```
/work-scaffold FEAT-001                    # scaffold + Cursor 프롬프트
/work-scaffold FEAT-001 --claude           # scaffold only (no Cursor)
/work-scaffold AUDIT-003                   # skip → /work-verify
```

## Type → Behavior

| Prefix | Action | Template |
|--------|--------|----------|
| `FEAT`, `FIX`, `CHORE`, `PERF`, `TEST` | File structure + stubs | `scaffold-feat.md` |
| `REFAC` | Migration map + rename list | `scaffold-refactor.md` |
| `AUDIT`, `DOCS` | Skip → redirect `/work-verify` | — |

## CRITICAL: Worktree-First Gate

**Before reading ANY work item file**, you MUST resolve the worktree path. The cwd copy of `status.md` is a stale seed — it does NOT reflect Codex/agent progress.

❌ WRONG: `Read work/items/FEAT-001-foo/status.md` (cwd — stale, shows `open` even when done)
✅ RIGHT: Resolve worktree path FIRST → `Read /abs/path/to/worktree/work/items/FEAT-001-foo/status.md`

## Steps

1. **Resolve**: Per `rules/collab-workflow.md` § Work Item Discovery, locate `work/items/{ID}-*/` (searches cwd, worktrees, sibling dirs). Resolve worktree per § Worktree Resolution. **Gate: do NOT read `status.md` until `$WT_PATH` is resolved and validated (`$WT_PATH ≠ repo root`).** Then read from `$WT_PATH/work/items/{SLUG}/`.
2. **Scaffold** (always — both modes): Read `contract.md`, create stub files with `NotImplementedError`, create test skeletons in worktree
3. **Cursor integration** (default mode only, skip with `--claude`): Generate `.cursor/rules/` (`{SLUG}-guard.mdc` + `{SLUG}-forbidden.mdc`) and Cursor Composer prompt
4. **Update status** → `scaffolded` (both control plane and worktree)
5. **Output**: Print created files summary. Default mode: also print Composer prompt with absolute worktree path (`{WT_PATH}`)

**MANDATORY NEXT-STEP TEMPLATE** — Print the block below as-is. Fill `«___»` slots with actual IDs. Do NOT add, remove, or reorder lines.

```
📋 다음 단계
  bash codex-run.sh «IDs»           # Codex 없으면: /work-impl «ID»
  /work-verify «ID»                 # Cursor 없으면: --claude
```

## Error Handling

- Missing work item: `ERROR: {ID} not found`
- Wrong status: `WARN: proceeding anyway`
- Missing worktree: `WARN: printing prompt without .cursor/rules/`
