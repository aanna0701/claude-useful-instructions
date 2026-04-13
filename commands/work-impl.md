# work-impl — Implement a Work Item in Its Worktree

Resolve a work item to its worktree and implement per contract. Claude fallback for when Codex is unavailable.

## Input

**$ARGUMENTS**: Work item ID (`FEAT-001`) or `all`.

## CRITICAL: Worktree-First Gate

**Before reading ANY work item file**, you MUST resolve the worktree path. The cwd copy of `status.md` is a stale seed — it does NOT reflect Codex/agent progress.

❌ WRONG: `Read work/items/FEAT-001-foo/status.md` (cwd — stale, shows `open` even when done)
✅ RIGHT: Resolve worktree path FIRST → `Read /abs/path/to/worktree/work/items/FEAT-001-foo/status.md`

## Steps

1. **Resolve**: Per `rules/collab-workflow.md` § Work Item Discovery (searches cwd, worktrees, sibling dirs). `FEAT-001` → find `work/items/FEAT-001-*/`. `all` → find planned/revising items. **Gate: do NOT proceed to step 2 until worktree path is resolved and validated (`$WT_PATH ≠ repo root`).**
2. **Switch to worktree**: Per `rules/collab-workflow.md` § Worktree Rules. All operations run in worktree. Never on `working_parent`.
3. **Sync preflight**: Preferred via `codex-run.sh` (auto-sync + `uv sync --frozen`). Manual: verify `git merge-base --is-ancestor`. Missing deps → `blocked` with `needs-sync`.
4. **Implement**: Acquire lock per `rules/collab-workflow.md` § Locks. Status → `implementing`. Follow contract strictly: Allowed Modifications only, never Forbidden Zones, satisfy tests, preserve invariants. If `revising`: resolve MUST-fix from review.md first.
5. **Complete & Push**: Status → `ready-for-review`. Update Changed Files, Verification, Doc Changes. Use `git add -f work/items/${SLUG}/`. Commit with `{type}({ID}): <description>`. The Draft PR already exists (created by `/work-plan`). Push updates the PR diff automatically.
6. **Relay**: Per `rules/collab-workflow.md` § Relay Protocol — append `impl` block to `relay.md` with changed files, commit hashes, and notes.
   - **PR Comment Relay** (per § PR Comment Relay):
     ```
     # Extract PR number from status.md PR field URL (e.g., .../pull/42 → 42)
     add_issue_comment(issue_number={PR_NUMBER}, body="<!-- relay:impl:{timestamp} --> ...")
     # Fallback: gh pr comment {PR_NUMBER} --body "..."
     ```

**MANDATORY NEXT-STEP TEMPLATE** — Print the block below as-is. Fill `«___»` slots with actual ID. Do NOT add, remove, or reorder lines.

```
📋 다음 단계
  /work-verify «ID»                 # Cursor 없으면: --claude
  /work-review «ID»
```
