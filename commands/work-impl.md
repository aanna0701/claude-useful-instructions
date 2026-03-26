# work-impl — Implement a Work Item in Its Worktree

Resolve a FEAT or GitHub Issue to its worktree and implement per contract.

---

## Input

**$ARGUMENTS**: Issue number (`#42`), FEAT ID (`FEAT-001`), or `all` (implement all open items).

If no arguments: list open work items and ask which to implement.

---

## Execution

### Step 1: Resolve to Work Item

- If `#42` → scan `work/items/FEAT-*/status.md` for `Issue` field matching `#42`
- If `FEAT-001` → find `work/items/FEAT-001-*/`
- If `all` → find all items with status `open` or `revision`

Error if not found: "No work item found for {arg}. Run /work-plan first."

### Step 2: Read Context

Read from the resolved work item directory:
1. `contract.md` — boundaries, interfaces, invariants, test requirements
2. `checklist.md` — verification items
3. `status.md` — worktree path, branch, current status
4. `review.md` (if exists and status is `revision`) — MUST-fix items

### Step 3: Switch to Worktree

Read `Worktree Path` from `status.md`. Verify it exists:
```bash
git worktree list | grep "<worktree_path>"
```

If worktree is missing (removed or never created), recreate it:
```bash
git worktree add "<worktree_path>" "<branch>"
```

**All file reads, edits, and commands from this point run in the worktree directory.**

### Step 4: Update Status

Update `status.md`:
- Status: `in-progress`
- Agent: the current agent identity (e.g., `codex`, `claude`)

### Step 5: Implement

Follow contract strictly: only Allowed Modifications, never Forbidden Zones, satisfy Test Requirements, preserve Invariants. If `revision`, resolve all `MUST-fix` from `review.md` first. Record ambiguities in `status.md` (never resolve unilaterally).

### Step 6: Update Status on Completion

Update `status.md`:
- Status: `done`
- Changed Files: list all modified/created files
- Doc Changes Needed: record any documentation updates that the implementer cannot make

### Step 7: Commit, Push & Draft PR

1. Commit changed files with `feat(FEAT-NNN): <description>`, push with `-u`.

2. Create a draft Pull Request:
   ```bash
   # Read merge target from contract's Branch Map section
   MERGE_TARGET=<from contract.md Branch Map>
   ISSUE=<from status.md Issue field>

   gh pr create \
     --base "$MERGE_TARGET" \
     --head feat/FEAT-NNN-slug \
     --title "FEAT-NNN: <readable title from brief>" \
     --body "## Objective
   <from brief.md>

   ## Changed Files
   <from status.md>

   ## Checklist
   <from checklist.md — checked items>

   ---
   Closes #${ISSUE}
   Work item: \`work/items/FEAT-NNN-slug/\`" \
     --draft
   ```

3. Update `status.md`: add `PR` field with the draft PR URL.

4. If `gh` is not available or fails, print warning and continue — PR can be created manually or by `/work-review` as a fallback.

Print summary: FEAT ID, issue, branch, PR (draft), status `done`, and next command `/work-review FEAT-NNN`.
