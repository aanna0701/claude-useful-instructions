# work-review — Review Implementation Against Contract

Compare implementation against contract, checklist, and brief. Supports batch review.

## Input

**$ARGUMENTS**: Work item IDs (e.g., `FEAT-001` or `FEAT-001 CHORE-002`).

No arguments: auto-glob for `ready-for-review` items.

## Steps

1. **Resolve worktree**: Per `rules/collab-workflow.md` § Worktree Rules. Set `$WORK_ROOT`. All reads from worktree.
2. **Read relay**: Per `rules/collab-workflow.md` § Relay Protocol — read `relay.md` for impl + verify results. Factor verify failures into review (raise severity if tests failed). Include relay summary in PR reviewer context.
3. **Pre-flight**: Read brief/contract/checklist/status (parallel). Require `ready-for-review` or `revising`. Acquire lock per § Locks.
4. **Branch map validation**: Per `rules/review-merge-policy.md` § Merge Gating. Check freshness, merge target, role consistency.
5. **Resolve PR**: `status.md` PR field > `gh pr list --head <branch>` > create as fallback.
6. **Review changed files**: From status.md `Changed Files` or `git log --name-only`.
7. **Generate review**: Spawn `pr-reviewer` agent. Decision: MERGE / REVISE / REJECT. Write `review.md`. Use `git add -f work/items/{SLUG}/`.
8. **Relay**: Append `review` block to `relay.md` with decision, must_fix/optional counts, and items list. Post PR comment with decision summary.

### MERGE

Per `rules/review-merge-policy.md`: check `merge_policy.ask_confirm_before_merge`, ready PR, submit review, squash-merge, delete branch, close issue, remove worktree, prune refs, doc sync on working parent, remove work item dir.

### REVISE

Write MUST-fix to review.md. Status → `revising`. Spawn `work-reviser` agent.

**MANDATORY OUTPUT**: The `📋 다음 단계` block below MUST appear verbatim in the final response, including when executed by a subagent.

```
📋 다음 단계 (REVISE)
  bash codex-run.sh {ID}           # Codex 없으면: /work-impl {ID}
  /work-verify {ID}                # Cursor 없으면: --claude
  /work-review {ID}
```

### REJECT

State reason. Close issue. Remove `work/items/{SLUG}/`.
