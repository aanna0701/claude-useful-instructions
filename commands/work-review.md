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

### Step 4: Review Changed Files

From `status.md` "Changed Files" section, read each modified file.
If "Changed Files" is empty, use `git diff main...HEAD` or `git log --name-only` to find changes.

### Step 5: Generate Review

Spawn `doc-writer-review` agent with `bundle: true`, passing contract + checklist + changed files as findings. The agent handles compliance checks, quality assessment, and decision (MERGE/REVISE/REJECT).

Write to `work/items/FEAT-NNN-slug/review.md`

### Step 6: Update Status

Update `status.md`:
- Status: `review`
- Agent: `Claude`

### Step 7: Execute Decision

**MERGE**:
1. Ask user: "FEAT-NNN: MERGE decision. Merge, delete branch, and clean up work item? [Y/n]"
2. If confirmed (or default Y):
   ```bash
   git merge feat/FEAT-NNN-slug
   git branch -d feat/FEAT-NNN-slug
   ```
3. Handle doc changes from `status.md` "Doc Changes Needed" section
4. Remove work item directory: `rm -r work/items/FEAT-NNN-slug/`
5. Update `work/dispatch.json`: remove the merged FEAT entry

**REVISE**: List specific items Codex must fix. Output re-dispatch command:
```
bash codex-run.sh FEAT-NNN
```
When writing `review.md`, include an explicit `MUST-fix` section with concrete file-level actions. On re-dispatch, `codex-run.sh` must inject `review.md` into the Codex prompt and Codex must treat every `MUST-fix` item as required before any optional cleanup.

**REJECT**: State reason. Remove work item directory: `rm -r work/items/FEAT-NNN-slug/`.

### Step 8: Batch Summary (when reviewing multiple items)

When reviewing multiple items, also check for "Doc Changes Needed" in each `status.md` and consolidate:

```
Review Complete
──────────────────────────────────────────────
  FEAT-001  duckdb-schema-cleanup      MERGED ✓ (cleaned up)
  FEAT-002  jwt-auth-middleware        MERGED ✓ (cleaned up)
  FEAT-003  refactor-logging           REVISE

Doc changes applied:
  FEAT-001: Updated docs/schema.md with new column list
  FEAT-002: Added API auth section to docs/api.md

Revisions needed:
  bash codex-run.sh FEAT-003
──────────────────────────────────────────────
```

Apply doc changes that Codex recorded but could not make (per collab-workflow rule).
