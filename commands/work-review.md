# work-review — Review Implementation Against Contract

Compare implementation against contract, checklist, and brief. Supports batch review.

---

## Input

**$ARGUMENTS**: Work item IDs (e.g., `FEAT-001` or `FEAT-001 CHORE-002`).

No arguments: auto-glob `work/items/*/status.md` for items with status `done`. If none found: "No work items ready for review."

**Batch mode**: Multiple IDs reviewed in parallel with consolidated summary.

---

## Execution Steps

### Step 1: Locate & Pre-flight

Resolve `$ARGUMENTS` to `work/items/` directory. Verify brief.md, contract.md, checklist.md, status.md exist. If status is `open`/`in-progress`, warn and confirm.

### Step 2: Read Work Item (parallel)

Read brief.md, contract.md, checklist.md, status.md in parallel.

### Step 2.5: Branch Map Validation

Per `rules/branch-map-policy.md` § Safety Rules and `rules/review-merge-policy.md` § Merge Gating.

From contract.md "## Branch Map" (fallback: `.claude/branch-map.yaml`, then upstream):
1. **Freshness**: branch must include all parent commits
2. **Merge target**: use contract's declared target for Step 7 merge
3. **Role consistency**: changed files must fall within declared role's paths

### Step 3: Resolve Worktree & PR

Use `Worktree Path` from status.md for all subsequent file reads/commands.

Find PR: `status.md` PR field > `gh pr list --head <branch>` > create as fallback (see `/work-impl` Step 7 format).

### Step 4: Review Changed Files

Read each file from "Changed Files" in status.md. Fallback: `git log --name-only` in worktree.

### Step 5: Generate Review

Spawn `doc-writer-review` agent with `bundle: true`, passing contract + checklist + changed files. Decision: MERGE / REVISE / REJECT.

Write to `work/items/{SLUG}/review.md`. Update status.md: Status → `review`, Agent → `Claude`.

### Step 6: Execute Decision

**MERGE**:
1. If Step 2.5 flagged freshness issues, block and suggest rebase first
2. Convert draft PR to ready: `gh pr ready <pr>`
3. Update PR body with review summary: `gh pr edit <pr> --body "..."`
4. Spawn `pr-reviewer` agent — reviews diff against contract, submits `gh pr review`, if APPROVE auto-merges via `gh pr merge --squash --delete-branch`
5. Update status.md: Status → `merged`, update PR field
6. Post-merge cleanup:
   - Close issue: `gh issue close <num> --comment "Merged via PR <url>"`
   - Remove worktree: `git worktree remove <path> && git branch -d <branch>`
   - Handle "Doc Changes Needed" from status.md
   - Remove work item: `rm -r work/items/{SLUG}/`
   - Update `work/dispatch.json`: remove merged entry

**REVISE**: Write review.md with explicit `MUST-fix` section. Spawn `work-reviser` agent. Print re-dispatch commands:
```
REVISE: {ID} (N MUST-fix items)
──────────────────────────────────────────────
/work-revise {ID}
bash codex-run.sh {ID}
codex exec --full-auto --cd <worktree_path> \
  "Revise {ID}. Read work/items/{SLUG}/review.md then contract.md. Follow AGENTS.md."
──────────────────────────────────────────────
```

**REJECT**: State reason. Close issue (`gh issue close <num> --reason "not planned"`). Remove `work/items/{SLUG}/`.

### Step 7: Batch Summary

```
Review Complete
──────────────────────────────────────────────
  FEAT-001  schema-cleanup    PR #51 (merged)   #42 closed
  DOCS-002  api-reference     PR #52 (merged)   #43 closed
  FIX-003   null-pointer      PR #53 (revise)   #44 open

Revisions needed:
  bash codex-run.sh FIX-003
──────────────────────────────────────────────
```

Apply doc changes that Codex recorded but could not make (per collab-workflow rule).
