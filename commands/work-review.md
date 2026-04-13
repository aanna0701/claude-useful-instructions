# work-review — Review Implementation Against Contract

Compare implementation against contract, checklist, and brief. Supports batch review.

## Input

**$ARGUMENTS**: Work item IDs (e.g., `FEAT-001` or `FEAT-001 CHORE-002`).

No arguments: auto-glob for `ready-for-review` items.

## CRITICAL: Worktree-First Gate

**Before reading ANY work item file**, you MUST resolve the worktree path. The cwd copy of `status.md` is a stale seed — it does NOT reflect Codex/agent progress.

❌ WRONG: `Read work/items/FEAT-001-foo/status.md` (cwd — stale, shows `open` even when done)
✅ RIGHT: Resolve worktree path FIRST → `Read /abs/path/to/worktree/work/items/FEAT-001-foo/status.md`

**Validation**: After resolving `$WT_PATH`, confirm the path does NOT equal `$(git rev-parse --show-toplevel)`. If it does, you are reading from main repo — STOP and re-resolve via `git worktree list`.

## Steps

1. **Resolve worktree**: Per `rules/collab-workflow.md` § Work Item Discovery (searches cwd, worktrees, sibling dirs), then § Worktree Resolution. Set `$WT_PATH` (absolute). **Gate: do NOT proceed to step 2 until `$WT_PATH` is resolved and validated.** All subsequent reads use `$WT_PATH/work/items/{SLUG}/`.
2. **Read relay**: Per `rules/collab-workflow.md` § Read Before Act — use `gh api .../issues/{PR}/comments` to read impl + verify results (filter `<!-- relay:impl: -->` and `<!-- relay:verify: -->`). Or read `pr-relay.md` / `relay.md` as fallback. Factor verify failures into review (raise severity if tests failed). Include relay summary in PR reviewer context.
3. **Pre-flight**: Read brief/contract/checklist/status (parallel). Require `ready-for-review` or `revising`. Acquire lock per § Locks.
4. **Branch map validation**: Per `rules/review-merge-policy.md` § Merge Gating. Check freshness, merge target, role consistency.
5. **Resolve PR**: `status.md` PR field > `gh pr list --head <branch>` > create as fallback.
6. **Review changed files**: From status.md `Changed Files` or `git log --name-only`.
7. **Generate review**: Spawn `pr-reviewer` agent. Decision: MERGE / REVISE / REJECT. Write `review.md`. Use `git add -f work/items/{SLUG}/`.
8. **Relay**: Append `review` block to `relay.md` with decision, must_fix/optional counts, and items list.
   - **PR Comment Relay** (per § PR Comment Relay):
     ```
     # Extract PR number from status.md PR field URL (e.g., .../pull/42 → 42)
     add_issue_comment(issue_number={PR_NUMBER}, body="<!-- relay:review:{timestamp} --> ...")
     # Fallback: gh pr comment {PR_NUMBER} --body "..."
     ```

### MERGE

Per `rules/review-merge-policy.md`, execute in order (stop on first failure):

1. **Acquire merge lock**: `source lib/merge-lock.sh && acquire_merge_lock` — serializes concurrent merges.
2. **Pre-merge fetch**: `git fetch origin {merge_target}` — ensure merge target is current.
3. **Check mergeability**: `gh pr view {pr} --json mergeable -q .mergeable` — must be `MERGEABLE`. If `CONFLICTING`, report conflicting files and STOP.
4. **Merge**: Delegate to `pr-reviewer` agent step 8 (squash merge → verify → cleanup).
5. **Post-merge**: Remove worktree (`git worktree remove`), prune refs, doc sync on working parent, remove `work/items/{SLUG}/` dir.
6. **Release lock**: Automatic on exit via trap.

**On failure at any step**: preserve branch + worktree, report error, release lock. Never delete branch on merge failure.

### REVISE

Write MUST-fix to review.md. Status → `revising`. Spawn `work-reviser` agent.

**MANDATORY NEXT-STEP TEMPLATE** — Print the block below as-is. Fill `«___»` slots with actual ID. Do NOT add, remove, or reorder lines.

```
📋 다음 단계 (REVISE)
  bash codex-run.sh «ID»           # Codex 없으면: /work-impl «ID»
  /work-verify «ID»                # Cursor 없으면: --claude
  /work-review «ID»
```

### REJECT

State reason. Close PR. Remove `work/items/{SLUG}/`.
