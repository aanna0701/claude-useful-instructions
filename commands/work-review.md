# work-review — Review Implementation Against Contract

Compare implementation against contract, checklist, and brief. Supports batch review.

---

## Input

**$ARGUMENTS**: Work item IDs (e.g., `FEAT-001` or `FEAT-001 CHORE-002`).

No arguments: auto-glob `work/items/*/status.md` for all item slugs, then apply Step 1 worktree-first resolution to each — check **worktree** status.md for `done` status. If none found: "No work items ready for review."

**Batch mode**: Multiple IDs reviewed in parallel with consolidated summary.

---

## Execution Steps

### Step 1: Locate & Resolve Worktree (CRITICAL — worktree-first)

Per `rules/collab-workflow.md` § Worktree-First File Resolution:

1. Resolve `$ARGUMENTS` to slug via `work/items/FEAT-NNN-*/` glob (cwd is fine here — just need the slug and worktree pointer)
2. **Discover worktree path** (resolution order — stop at first hit):
   a. `work/dispatch.json` → `.items[] | select(.feat_id == $ID) | .worktree_path`
   b. cwd `status.md` → `Worktree Path` field (may be stale — only use as pointer)
   c. Convention: `../${PROJECT_DIR_NAME}-${SLUG}/`
3. **If worktree path found and exists**: read `status.md` from **worktree** (`${WORKTREE}/work/items/${SLUG}/status.md`). This is the authoritative copy.
4. **Fallback**: if no worktree exists (already merged or local-only), use cwd copy.

**Why**: Codex updates status.md in the worktree. The main repo copy is a stale seed — it will say `open` even after Codex marks `done`. Always read from worktree first.

Set `$WORK_ROOT` = resolved worktree path (or cwd as fallback). ALL subsequent file reads use `$WORK_ROOT`.

### Step 2: Pre-flight & Read Work Item (parallel)

Using `$WORK_ROOT/work/items/${SLUG}/`:
- Verify brief.md, contract.md, checklist.md, status.md exist
- Read all four in parallel
- If status is `open`/`in-progress`, warn and confirm

### Step 2.5: Branch Map Validation

Per `rules/branch-map-policy.md` § Safety Rules and `rules/review-merge-policy.md` § Merge Gating.

From contract.md "## Branch Map" (fallback: `.claude/branch-map.yaml`, then upstream):
1. **Freshness**: branch must include all parent commits
2. **Merge target**: use contract's declared target for Step 7 merge
3. **Role consistency**: changed files must fall within declared role's paths

### Step 3: Resolve PR

Find PR: `status.md` PR field > `gh pr list --head <branch>` > create as fallback (see `/work-impl` Step 7 format).

### Step 4: Review Changed Files

Read each file from "Changed Files" in status.md (already read from `$WORK_ROOT`). Fallback: `git log --name-only` in worktree.

### Step 5: Generate Review

Spawn `doc-writer-review` agent with `bundle: true`, passing contract + checklist + changed files. Decision: MERGE / REVISE / REJECT.

Write to `work/items/{SLUG}/review.md`. Update status.md: Status → `review`, Agent → `Claude`.

### Step 6: Execute Decision

**MERGE**:
1. If Step 2.5 flagged freshness issues, block and suggest rebase first
2. Check `merge_policy.ask_confirm_before_merge` in branch-map.yaml — if true, ask user before proceeding; if false, auto-merge without prompt
3. Convert draft PR to ready: `gh pr ready <pr>`
4. Update PR body with review summary: `gh pr edit <pr> --body "..."`
5. Spawn `pr-reviewer` agent — reviews diff against contract, submits `gh pr review`, if APPROVE auto-merges via `gh pr merge --squash --delete-branch`
6. Update status.md: Status → `merged`, update PR field
7. Post-merge cleanup:
   - Close issue: `gh issue close <num> --comment "Merged via PR <url>"`
   - Remove worktree: `git worktree remove <path> && git branch -d <branch>`
   - Update `work/dispatch.json`: remove merged entry
8. **Doc sync** (automatic — no user prompt):
   - `git pull` on current branch (working parent) to pick up squash-merged changes
   - Read "Doc Changes Needed" section from status.md (saved before worktree removal)
   - If doc changes exist OR merged files touch `docs/`, `README.md`, or config:
     - Run `/sync-docs` targeting the affected doc paths
     - Commit doc updates: `docs: sync after {FEAT-ID} merge`
     - Push to working parent
   - Remove work item dir last: `rm -r work/items/{SLUG}/`

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

Doc changes are applied automatically per item during Step 6 MERGE (no manual action needed).
