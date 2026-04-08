# work-impl — Implement a Work Item in Its Worktree

Resolve a work item to its worktree and implement per contract. Claude fallback for when Codex is unavailable.

## Input

**$ARGUMENTS**: Issue number (`#42`), work item ID (`FEAT-001`), or `all`.

## Steps

1. **Resolve**: Per `rules/collab-workflow.md` § Work Item Discovery (searches cwd, worktrees, sibling dirs). `#42` → scan status.md for issue number. `FEAT-001` → find `work/items/FEAT-001-*/`. `all` → find planned/revising items.
2. **Switch to worktree**: Per `rules/collab-workflow.md` § Worktree Rules. All operations run in worktree. Never on `working_parent`.
3. **Sync preflight**: Preferred via `codex-run.sh` (auto-sync + `uv sync --frozen`). Manual: verify `git merge-base --is-ancestor`. Missing deps → `blocked` with `needs-sync`.
4. **Implement**: Acquire lock per `rules/collab-workflow.md` § Locks. Status → `implementing`. Follow contract strictly: Allowed Modifications only, never Forbidden Zones, satisfy tests, preserve invariants. If `revising`: resolve MUST-fix from review.md first.
5. **Complete & Push**: Status → `ready-for-review`. Update Changed Files, Verification, Doc Changes. Use `git add -f work/items/${SLUG}/`. Commit with `{type}({ID}): <description>`, push with `-u`. Create draft PR targeting contract's merge target. Update status.md with PR.
6. **Relay**: Per `rules/collab-workflow.md` § Relay Protocol — append `impl` block to `relay.md` with changed files, commit hashes, and notes. Post PR comment if PR exists.

**MANDATORY NEXT-STEP TEMPLATE** — Print the block below as-is. Fill `«___»` slots with actual ID. Do NOT add, remove, or reorder lines.

```
📋 다음 단계
  /work-verify «ID»                 # Cursor 없으면: --claude
  /work-review «ID»
```
