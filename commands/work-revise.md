# work-revise — Re-dispatch REVISE Items

## Input

**$ARGUMENTS**: Work item IDs (e.g., `FIX-003`). No arguments: auto-glob items with REVISE decision.

## Execution

Per `rules/collab-workflow.md` § Worktree Rules, read review.md and status.md from worktree.

1. **Read relay**: Per `rules/collab-workflow.md` § Relay Protocol — read `relay.md` for review `items` (MUST-fix list). These are the authoritative fix targets; do not re-derive from `review.md` if relay exists.
2. **Dispatch**: Spawn `work-reviser` agent per item (parallel). Each resolves MUST-fix, updates status → `revising`. Same branch and worktree — never create a second worktree.
3. **Relay**: Append `revise` block to `relay.md` with `fixed` list and `remaining` count. Post PR comment.

## Summary

Print dispatched items with MUST-fix counts, then:

**MANDATORY OUTPUT**: The `📋 다음 단계` block below MUST appear verbatim in the final response, including when executed by a subagent.

```
📋 다음 단계
  bash codex-run.sh {IDs}          # Codex 없으면: /work-impl {ID}
  /work-verify {ID}                # Cursor 없으면: --claude
  /work-review {IDs}
```
