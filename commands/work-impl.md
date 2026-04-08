# work-impl — Implement a Work Item in Its Worktree

Resolve a work item to its worktree and implement per contract. Claude fallback for when Codex is unavailable.

## Input

**$ARGUMENTS**: Issue number (`#42`), work item ID (`FEAT-001`), or `all`.

## CRITICAL: Worktree-First Gate

**Before reading ANY work item file**, you MUST resolve the worktree path. The cwd copy of `status.md` is a stale seed — it does NOT reflect Codex/agent progress.

❌ WRONG: `Read work/items/FEAT-001-foo/status.md` (cwd — stale, shows `open` even when done)
✅ RIGHT: Resolve worktree path FIRST → `Read /abs/path/to/worktree/work/items/FEAT-001-foo/status.md`

## Steps

1. **Resolve**: Per `rules/collab-workflow.md` § Work Item Discovery (searches cwd, worktrees, sibling dirs). `#42` → scan status.md for issue number. `FEAT-001` → find `work/items/FEAT-001-*/`. `all` → find planned/revising items. **Gate: do NOT proceed to step 2 until worktree path is resolved and validated (`$WT_PATH ≠ repo root`).**
2. **Switch to worktree**: Per `rules/collab-workflow.md` § Worktree Rules. All operations run in worktree. Never on `working_parent`.
3. **Sync preflight**: Preferred via `codex-run.sh` (auto-sync + `uv sync --frozen`). Manual: verify `git merge-base --is-ancestor`. Missing deps → `blocked` with `needs-sync`.
4. **Implement**: Acquire lock per `rules/collab-workflow.md` § Locks. Status → `implementing`. Follow contract strictly: Allowed Modifications only, never Forbidden Zones, satisfy tests, preserve invariants. If `revising`: resolve MUST-fix from review.md first.
5. **Complete & Push**: Status → `ready-for-review`. Update Changed Files, Verification, Doc Changes. Use `git add -f work/items/${SLUG}/`. Commit with `{type}({ID}): <description>`. A draft PR is created automatically by the `auto-pr-commit` hook on first commit (base = the branch the worktree was created from). If running in Codex sandbox where hooks don't fire, `codex-run.sh` handles push + PR.
6. **Relay**: Per `rules/collab-workflow.md` § Relay Protocol — append `impl` block to `relay.md` with changed files, commit hashes, and notes.
   - **PR Comment Relay**: Use MCP `add_issue_comment` to post relay comment with `<!-- relay:impl:{timestamp} -->` marker (per § PR Comment Relay). Fallback: `gh pr comment`.
   - **Issue Label**: Use MCP `update_issue` to set `status:ready-for-review`. Fallback: `gh issue edit`.

**MANDATORY NEXT-STEP TEMPLATE** — Print the block below as-is. Fill `«___»` slots with actual ID. Do NOT add, remove, or reorder lines.

```
📋 다음 단계
  /work-verify «ID»                 # Cursor 없으면: --claude
  /work-review «ID»
```
