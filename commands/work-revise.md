# work-revise — Re-dispatch Failed Review Items

Re-dispatch work items that received a REVISE decision from `/work-review`.

---

## Input

**$ARGUMENTS**: One or more FEAT IDs (e.g., `FEAT-003`) or a branch glob (e.g., `feat-*`).

If no arguments provided:
1. Glob `work/items/FEAT-*/review.md` for items with REVISE decision
2. If found, revise all of them
3. If none found: "No items pending revision."

---

## Execution

### Step 1: Resolve Work Items

For each argument:
- If FEAT ID: resolve to `work/items/FEAT-NNN-*/`
- If glob pattern: match against `work/items/` directories, filter to those with `review.md` containing REVISE decision

### Step 2: Dispatch

Spawn `work-reviser` agent for each item (parallel if multiple).

The agent:
1. Extracts MUST-fix items from review.md
2. Updates status.md to `revision`
3. Re-dispatches to the appropriate target (Codex or agent)

### Step 3: Summary

Print consolidated table:
```
Revision Dispatched
──────────────────────────────────────────────
  FEAT-003  refactor-logging    3 MUST-fix  → codex     #44 open
  FEAT-005  cache-invalidation  1 MUST-fix  → agent     #46 open
──────────────────────────────────────────────
```
