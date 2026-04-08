# work-revise — Re-dispatch REVISE Items

## Input

**$ARGUMENTS**: Work item IDs (e.g., `FIX-003`). No arguments: auto-glob items with REVISE decision.

## CRITICAL: Worktree-First Gate

**Before reading ANY work item file**, you MUST resolve the worktree path. The cwd copy of `status.md` is a stale seed — it does NOT reflect Codex/agent progress.

❌ WRONG: `Read work/items/FEAT-001-foo/status.md` (cwd — stale, shows `open` even when done)
✅ RIGHT: Resolve worktree path FIRST → `Read /abs/path/to/worktree/work/items/FEAT-001-foo/status.md`

## Execution

Per `rules/collab-workflow.md` § Work Item Discovery (searches cwd, worktrees, sibling dirs), then § Worktree Resolution. **Gate: do NOT read `review.md` or `status.md` until `$WT_PATH` is resolved and validated (`$WT_PATH ≠ repo root`).** Read from `$WT_PATH/work/items/{SLUG}/`.

1. **Read relay**: Per `rules/collab-workflow.md` § Read Before Act — use `gh api .../issues/{PR}/comments` to read review results (filter `<!-- relay:review: -->`). Parse `items` for MUST-fix list. Or read `pr-relay.md` / `relay.md` as fallback. These are the authoritative fix targets; do not re-derive from `review.md` if relay exists.
2. **Dispatch**: Spawn `work-reviser` agent per item (parallel). Each resolves MUST-fix, updates status → `revising`. Same branch and worktree — never create a second worktree.
3. **Relay**: Append `revise` block to `relay.md` with `fixed` list and `remaining` count.
   - **PR Comment Relay** (per § PR Comment Relay — use **PR number**, NOT Issue number):
     ```
     # Extract PR number from status.md PR field URL (e.g., .../pull/42 → 42)
     add_issue_comment(issue_number={PR_NUMBER}, body="<!-- relay:revise:{timestamp} --> ...")
     # Fallback: gh pr comment {PR_NUMBER} --body "..."
     # No PR yet? Skip relay comment (relay.md suffices).
     ```

## Summary

Print dispatched items with MUST-fix counts, then:

**MANDATORY NEXT-STEP TEMPLATE** — Print the block below as-is. Fill `«___»` slots with actual IDs. Do NOT add, remove, or reorder lines.

```
📋 다음 단계
  bash codex-run.sh «IDs»          # Codex 없으면: /work-impl «ID»
  /work-verify «ID»                # Cursor 없으면: --claude
  /work-review «IDs»
```
