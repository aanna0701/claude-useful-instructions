# work-scaffold — Scaffold File Structures from Contracts

Generate Cursor Composer prompts for scaffolding, or execute directly with `--claude`.

## Input

```
/work-scaffold FEAT-001                    # Cursor 프롬프트 생성
/work-scaffold FEAT-001 --claude           # Claude가 직접 scaffold
/work-scaffold AUDIT-003                   # skip → /work-verify
```

## Type → Behavior

| Prefix | Action | Template |
|--------|--------|----------|
| `FEAT`, `FIX`, `CHORE`, `PERF`, `TEST` | File structure + stubs | `scaffold-feat.md` |
| `REFAC` | Migration map + rename list | `scaffold-refactor.md` |
| `AUDIT`, `DOCS` | Skip → redirect `/work-verify` | — |

## Steps

1. **Resolve**: Locate `work/items/{ID}-*/`, read `status.md` (planned/scaffolded), resolve worktree per `rules/collab-workflow.md` § Worktree Rules
2. **Scaffold**:
   - **Default**: Spawn `cursor-prompt-builder` agent (`mode=scaffold`). Returns Cursor Composer prompt.
   - **`--claude`**: Read `contract.md`, create stub files with `NotImplementedError`, create test skeletons. Skip `.cursor/rules/`.
3. **Generate `.cursor/rules/`** (Cursor mode only): `{SLUG}-guard.mdc` + `{SLUG}-forbidden.mdc` in worktree
4. **Update status** → `scaffolded` (both control plane and worktree)
5. **Output**: Print prompt with absolute worktree path (`{WT_PATH}`)

**MANDATORY OUTPUT**: The `📋 다음 단계` block below MUST appear verbatim in the final response, including when executed by a subagent.

```
📋 다음 단계
  bash codex-run.sh {IDs}           # Codex 없으면: /work-impl {ID}
  /work-verify {ID}                 # Cursor 없으면: --claude
```

## Error Handling

- Missing work item: `ERROR: {ID} not found`
- Wrong status: `WARN: proceeding anyway`
- Missing worktree: `WARN: printing prompt without .cursor/rules/`
