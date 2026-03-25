# work-review — Review Codex Implementation Against Contract

Review completed work item(s) by comparing the implementation against the contract, checklist, and brief. Supports single or batch review.

---

## Input

**$ARGUMENTS**: One or more work item IDs (e.g., `FEAT-001` or `FEAT-001 FEAT-002 FEAT-003`).

If no arguments provided:
1. Glob `work/items/FEAT-*/status.md` for items with status "done"
2. If found, review all of them (batch mode)
3. If none found, report: "No work items ready for review."

**Batch mode**: When multiple FEAT IDs are given, review each in parallel using concurrent agents, then present a consolidated summary.

---

## Execution Steps

### Step 1: Locate Work Item

Resolve `$ARGUMENTS` to a directory under `work/items/`.
Verify all required files exist: brief.md, contract.md, checklist.md, status.md.

### Step 2: Pre-flight Check

Read `status.md`. Verify status is `done` or `review`.
If status is `open` or `in-progress`, warn:
> "Work item FEAT-NNN is still {status}. Review anyway? (implementation may be incomplete)"

### Step 3: Read Work Item

Read in parallel:
- `brief.md` — scope and objective
- `contract.md` — boundaries, interfaces, invariants, test requirements
- `checklist.md` — verification items
- `status.md` — changed files, progress, ambiguities

### Step 3.5: Branch Map Validation

Read the "## Branch Map" section from `contract.md`. If present:

1. **Freshness check**: Compare the implementation branch against the declared `Parent Branch`:
   ```bash
   git rev-list --left-right --count <parent>...<branch>
   ```
   If the branch is behind its parent, warn: "Branch is N commits behind {parent}. Recommend rebase before merge."

2. **Merge target**: Use `Merge Target` from the contract (not a hardcoded branch) for the merge in Step 8.

3. **Role consistency**: Verify that changed files (from status.md) fall within the declared role's expected paths. Flag unexpected path modifications.

If no Branch Map section exists (legacy work items), attempt to read `.claude/branch-map.yaml` directly. If that also doesn't exist, fall back to default behavior (merge into current branch's upstream).

### Step 4: Resolve Implementation Worktree

Read `Worktree` and `Worktree Path` from `status.md`. If it differs from the current cwd, use that path for all file reads, git commands, and test runs in subsequent steps. See `rules/collab-workflow.md` → "Review worktree rule" for rationale.

### Step 5: Review Changed Files

From `status.md` "Changed Files" section, read each modified file **from the resolved worktree** (Step 4).
If "Changed Files" is empty, use `git log --name-only` on the implementation worktree to find changes.

### Step 6: Generate Review

Spawn `doc-writer-review` agent with `bundle: true`, passing contract + checklist + changed files as findings. The agent handles compliance checks, quality assessment, and decision (MERGE/REVISE/REJECT).

Write to `work/items/FEAT-NNN-slug/review.md`

### Step 7: Update Status

Update `status.md`:
- Status: `review`
- Agent: `Claude`

### Step 8: Execute Decision

**MERGE**:
1. Resolve merge target: use `Merge Target` from contract's Branch Map section, or fall back to the branch's upstream.
2. If Step 3.5 flagged freshness issues, block merge and suggest rebase first.
3. Create Pull Request:
   ```bash
   gh pr create \
     --base <merge_target> \
     --head feat/FEAT-NNN-slug \
     --title "FEAT-NNN: <readable title from brief>" \
     --body "<body>"
   ```
   PR body format:
   ```
   ## Objective
   <from brief.md>

   ## Review Summary
   <verdict and key findings from review.md>

   ## Changed Files
   <from status.md>

   ## Checklist
   <from checklist.md — checked items>

   ---
   Closes #<issue_number>
   Work item: `work/items/FEAT-NNN-slug/`
   ```
   The `Closes #N` line auto-closes the linked GitHub Issue when the PR is merged.
4. Link PR to Issue (if issue exists):
   ```bash
   gh issue comment <number> --body "PR created: <pr_url>"
   ```
5. **Auto PR review**: Spawn `pr-reviewer` agent with the PR number, FEAT ID, work item directory, and repo root. The agent reviews the diff against the contract and submits an `APPROVE` or `REQUEST_CHANGES` review via `gh pr review`.
6. Update `status.md`: set Status to `merged`, add `PR` field with the PR URL.
7. Print: "PR created: <pr_url>. Review submitted. Merge on GitHub to complete."
8. **Post-merge cleanup** (run after PR is merged on GitHub, or via `/work-status` detecting merged PRs):
   - Remove worktree:
     ```bash
     git worktree remove <worktree_path>
     git branch -d feat/FEAT-NNN-slug
     ```
   - Handle doc changes from `status.md` "Doc Changes Needed" section
   - Remove work item directory: `rm -r work/items/FEAT-NNN-slug/`
   - Update `work/dispatch.json`: remove the merged FEAT entry

**REVISE**: Write `review.md` with an explicit `MUST-fix` section (concrete file-level actions). Then spawn `work-reviser` agent for the FEAT — it extracts MUST-fix items, updates status to `revision`, and re-dispatches to the appropriate target (Codex or agent).

After writing `review.md`, **always print the re-dispatch commands**:
```
REVISE: FEAT-NNN (N MUST-fix items)
──────────────────────────────────────────────
# Re-dispatch (pick one):
  /work-revise FEAT-NNN
  bash codex-run.sh FEAT-NNN
  codex exec --full-auto --cd <worktree_path> \
    "Revise FEAT-NNN. Read work/items/FEAT-NNN-slug/review.md for MUST-fix items, then contract.md. Follow AGENTS.md."
──────────────────────────────────────────────
```

**REJECT**: State reason. Close GitHub Issue if exists (`gh issue close <number> --reason "not planned" --comment "Rejected: <reason>"`). Remove work item directory: `rm -r work/items/FEAT-NNN-slug/`.

### Step 9: Batch Summary (when reviewing multiple items)

When reviewing multiple items, also check for "Doc Changes Needed" in each `status.md` and consolidate:

```
Review Complete
──────────────────────────────────────────────
  FEAT-001  duckdb-schema-cleanup      PR #51 → research   #42 linked
  FEAT-002  jwt-auth-middleware        PR #52 → research   #43 linked
  FEAT-003  refactor-logging           REVISE               #44 open

PRs ready to merge on GitHub:
  https://github.com/org/repo/pull/51
  https://github.com/org/repo/pull/52

Revisions needed:
  bash codex-run.sh FEAT-003
──────────────────────────────────────────────
```

Apply doc changes that Codex recorded but could not make (per collab-workflow rule).
