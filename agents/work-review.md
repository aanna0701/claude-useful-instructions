---
name: work-review
description: Review implementation against contract, checklist, and brief. Supports batch review of one or more work item IDs.
---

## Input

- `feat_id`: one or more work item IDs (e.g., `FIX-159`, `FIX-159 CHORE-162 FIX-164`). Omit to auto-glob `ready-for-review` items.
- `work_dir`: (optional) resolved worktree path; auto-resolved if not provided.

## CRITICAL: Worktree-First Gate

**Before reading ANY work item file**, resolve the worktree path. The cwd copy of `status.md` is a stale seed.

❌ WRONG: `Read work/items/FEAT-001-foo/status.md` (cwd — stale)
✅ RIGHT: Resolve `$WT_PATH` first → `Read /abs/path/to/worktree/work/items/FEAT-001-foo/status.md`

**Validation**: After resolving `$WT_PATH`, confirm it does NOT equal `$(git rev-parse --show-toplevel)`. If equal, re-resolve via `git worktree list`.

## Steps

1. **Resolve worktree**: Per `rules/collab-workflow.md` § Work Item Discovery, then § Worktree Resolution. Set `$WT_PATH` (absolute). **Gate: do NOT proceed until `$WT_PATH` is validated.** All subsequent reads use `$WT_PATH/work/items/{SLUG}/`.

2. **Read relay**: Use `gh api .../issues/{PR}/comments` to read impl + verify results (filter `<!-- relay:impl: -->` and `<!-- relay:verify: -->`). Or read `pr-relay.md` / `relay.md` as fallback. Factor verify failures into review severity.

3. **Pre-flight** (parallel): Read `brief.md`, `contract.md`, `checklist.md`, `status.md`. Require status `ready-for-review` or `revising`.

4. **Branch map validation**: Per `rules/review-merge-policy.md` § Merge Gating. Check freshness, merge target, role consistency.

5. **Resolve PR**: `status.md` PR field → `gh pr list --head <branch>` → create as fallback.

6. **Review changed files**: From `status.md` `Changed Files` or `git log --name-only`.

7. **Generate review**: Spawn `pr-reviewer` agent. Decision: MERGE / REVISE / REJECT. Write `review.md`. Stage with `git add -f work/items/{SLUG}/`.

8. **Relay**: Append `review` block to `relay.md`. Post PR comment:
   ```
   <!-- relay:review:{ISO-8601} -->
   ### review — {MERGE|REVISE|REJECT}
   **agent:** claude-code
   **decision:** {MERGE|REVISE|REJECT}
   **must_fix:** {count}

   > {1-3 line summary}
   ```
   Use `mcp__plugin_ecc_github__add_issue_comment(issue_number={PR_NUMBER})` or fallback `gh pr comment {PR_NUMBER} --body "..."`.

### MERGE

Execute in order (stop on first failure):

1. **Acquire merge lock**: `source lib/merge-lock.sh && acquire_merge_lock`
2. **Pre-merge fetch**: `git fetch origin {merge_target}`
3. **Check mergeability**: `gh pr view {pr} --json mergeable -q .mergeable` — must be `MERGEABLE`. If `CONFLICTING`, report files and STOP.
4. **Merge**: Delegate to `pr-reviewer` agent (squash merge → verify → cleanup).
5. **Post-merge**: Remove worktree (`git worktree remove`), prune refs, remove `work/items/{SLUG}/`.
6. **Release lock**: Automatic via trap.

**On failure**: preserve branch + worktree, report error, release lock. Never delete branch on merge failure.

### REVISE

Write MUST-fix items to `review.md`. Status → `revising`. Spawn `work-reviser` agent.

Print this block exactly (fill `«ID»` slots):

```
📋 다음 단계 (REVISE)
  bash codex-run.sh «ID»           # Codex 없으면: /work-impl «ID»
  /work-verify «ID»                # Cursor 없으면: --claude
  /work-review «ID»
```

### REJECT

State reason. Close PR. Remove `work/items/{SLUG}/`.

## Batch Mode

Multiple IDs: resolve each worktree, run steps 1–8 in parallel per item, print consolidated summary.

## Rules

- Never read work item files from cwd — always use resolved `$WT_PATH`
- Never delete a branch on merge failure
- Never close the GitHub Issue until MERGE (issues auto-close via PR link)
