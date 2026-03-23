# work-review — Review Codex Implementation Against Contract

Review a completed work item by comparing the implementation against the contract, checklist, and brief.

---

## Input

**$ARGUMENTS**: Work item ID (e.g., `FEAT-001` or `FEAT-001-user-auth`).

If no arguments provided:
1. Glob `work/items/FEAT-*/status.md` for items with status "done" or "review"
2. If exactly one found, use it. If multiple, list them and ask user to choose.
3. If none found, report: "No work items ready for review."

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

### Step 4: Gemini Pre-Review (optional)

If Gemini MCP is available, call for neutral third-party audit:

```
gemini_audit_implementation(
  contract_path="work/items/FEAT-NNN-slug/contract.md",
  changed_files=[...from status.md Changed Files...],
  checklist_path="work/items/FEAT-NNN-slug/checklist.md"
)
```

Save Gemini's raw audit to `work/items/FEAT-NNN-slug/review-gemini.md`.
Use findings to inform Claude's own review in the next step.
**Skip if**: Gemini MCP not available.

### Step 5: Review Changed Files

From `status.md` "Changed Files" section, read each modified file.
If "Changed Files" is empty, use `git diff main...HEAD` or `git log --name-only` to find changes.

Check against contract (informed by Gemini audit if available):
1. **Boundary compliance**: Only "Allowed Modifications" files changed? Any "Forbidden Zone" violations?
2. **Interface compliance**: Do implementations match interface specs?
3. **Invariant compliance**: Are all invariants preserved?
4. **Test compliance**: Do tests exist per "Test Requirements"?
5. **Checklist verification**: Walk through each checklist item, mark pass/fail.

### Step 6: Generate Review

**Preferred**: Spawn `doc-writer-review` agent with `bundle: true` and findings.

**Fallback**: Read template from `.claude/templates/work-item/review.md`, fill in:
- Contract compliance table (item → Pass/Fail/Partial)
- Deviations from contract
- Quality checks
- At least 1 lesson learned
- Decision: MERGE / REVISE / REJECT

Write to `work/items/FEAT-NNN-slug/review.md`

### Step 7: Update Status

Update `status.md`:
- Status: `review`
- Agent: `Claude`

### Step 8: Report Decision

Print the decision with details:

**MERGE**: "Ready to merge. Suggest: `git merge feat/FEAT-NNN-slug`"

**REVISE**: List specific items Codex must fix. Output a revised Codex prompt:
```
Read work/items/FEAT-NNN-slug/review.md for required revisions.
Fix the listed items and update status.md when done.
```

**REJECT**: State reason clearly. Suggest whether to rework or abandon the work item.
