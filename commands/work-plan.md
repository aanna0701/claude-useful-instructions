# work-plan — Create Work Items for Claude-Codex Delegation

Create work item bundles (brief + contract + checklist + status) for delegating implementation to Codex. Automatically splits topics into parallelizable sub-tasks for maximum Codex throughput.

---

## Input

**$ARGUMENTS**: One or more feature topics (newline-separated), or a path to a source RFC/ADR.

If no arguments provided, ask:
> "What feature(s) should I plan? Provide topic(s) or path to source RFC/ADR."

```
/work-plan DuckDB schema cleanup
```

```
/work-plan
DuckDB schema cleanup
Add JWT auth middleware
```

---

## Execution Steps

### Step 1: Gather Context

If `$ARGUMENTS` is a file path (RFC/ADR), read it for context.

For each topic, gather or infer:
- **Objective**: What this work achieves (1-3 sentences)
- **Source**: Path to RFC/ADR (if available)
- **Scope**: What is in-scope vs out-of-scope
- **Boundaries**: Files/modules that may or may not be changed

### Step 2: Decompose into Parallel Sub-tasks

For **each topic**, analyze the scope and identify independent implementation units. A unit is independent when it:
- Touches a **disjoint set of files/modules** from other units
- Has **no runtime dependency** on other units during implementation
- Can be **tested in isolation**

Decomposition strategy:
1. **By module/table**: Each module or data model that changes independently (e.g., `frames` table vs `windows` table)
2. **By layer**: API layer vs data layer vs test layer (only if truly independent)
3. **By feature boundary**: Separate functional concerns within the same topic

Each sub-task becomes its own FEAT with its own contract boundaries.

**Example** — single topic "DuckDB schema cleanup":
```
Input:  "DuckDB schema cleanup" (removes dead columns from 3 tables + ENUMs)

Analysis:
  frames table changes     → src/models/frames.py, tests/models/test_frames.py
  windows table changes    → src/models/windows.py, tests/models/test_windows.py
  ENUM removal             → src/schema/enums.py
  migration script         → migrations/ (depends on all above)

Decomposition:
  FEAT-001  frames-column-cleanup     (independent)
  FEAT-002  windows-column-cleanup    (independent)
  FEAT-003  enum-removal              (independent)
  FEAT-004  schema-migration          (depends_on: 001, 002, 003)
```

**When NOT to split:**
- The scope is small enough that splitting adds overhead (< 3 files total)
- All changes are tightly coupled (same function, same class)
- The user explicitly requests a single work item

If unsure about the split, propose the decomposition and ask the user to confirm.

### Step 3: Assign IDs

```bash
# Find next FEAT number
ls work/items/ 2>/dev/null | grep -oP 'FEAT-\K\d+' | sort -n | tail -1
```

Assign sequential `FEAT-NNN` (3-digit, zero-padded). First item is `FEAT-001`.
Create slug from sub-task: lowercase, kebab-case, max 30 chars.

For sub-tasks from the same parent topic, use a consistent prefix:
```
FEAT-001-duckdb-frames-cleanup
FEAT-002-duckdb-windows-cleanup
FEAT-003-duckdb-enum-removal
FEAT-004-duckdb-migration
```

### Step 4: Generate Work Items (parallel)

Spawn **parallel agents**, one per FEAT:
```
Agent 1: Generate FEAT-001 (brief + contract + checklist + status)
Agent 2: Generate FEAT-002 (brief + contract + checklist + status)
Agent 3: Generate FEAT-003 (brief + contract + checklist + status)
Agent 4: Generate FEAT-004 (brief + contract + checklist + status)
```

Each agent:
1. **Generate Brief** — Spawn `doc-writer-task` agent with `bundle: true`, or fill from `.claude/templates/work-item/brief.md`
2. **Generate Contract** — Spawn `doc-writer-contract`, or fill from `.claude/templates/work-item/contract.md`. **Ensure Allowed Modifications are disjoint** from sibling FEATs.
3. **Generate Checklist** — Spawn `doc-writer-checklist` agent, or fill from template
4. **Initialize Status** — From `.claude/templates/work-item/status.md`, set status=open, agent=TBD

Write all files to `work/items/FEAT-NNN-slug/`.

### Step 5: Boundary Overlap Check

**Always run when 2+ work items exist** (including previously existing open items in `work/items/`).

Extract "Allowed Modifications" from each contract. For each pair of items (i, j):
```
overlap = allowed_paths[i] ∩ allowed_paths[j]
```

Path matching rules:
- `src/models/` overlaps with `src/models/user.py` (directory contains file)
- `src/models/user.py` overlaps with `src/models/user.py` (exact match)
- `src/models/` does NOT overlap with `src/views/` (independent)

Print the **boundary matrix**:

```
Boundary Check
──────────────────────────────────────────────
          FEAT-001    FEAT-002    FEAT-003    FEAT-004
FEAT-001     —           ✓           ✓         dep
FEAT-002     ✓           —           ✓         dep
FEAT-003     ✓           ✓           —         dep
FEAT-004    dep         dep         dep          —

dep = dependency (FEAT-004 depends on 001, 002, 003)
──────────────────────────────────────────────
✓ All boundaries independent — safe for parallel dispatch
```

**If overlaps found:**
1. Print conflicting files and which FEATs touch them
2. Suggest: narrow one contract's boundaries, or merge the overlapping FEATs back into one
3. Ask user to confirm or adjust

### Step 6: Generate Dispatch Manifest

Create or update `work/dispatch.json`:

```json
{
  "batch_id": "BATCH-YYYYMMDD-HHMM",
  "created": "YYYY-MM-DD HH:MM",
  "parent_topic": "DuckDB schema cleanup",
  "items": [
    {
      "feat_id": "FEAT-001",
      "slug": "FEAT-001-duckdb-frames-cleanup",
      "status": "open",
      "depends_on": [],
      "conflicts_with": []
    },
    {
      "feat_id": "FEAT-004",
      "slug": "FEAT-004-duckdb-migration",
      "status": "open",
      "depends_on": ["FEAT-001", "FEAT-002", "FEAT-003"],
      "conflicts_with": []
    }
  ],
  "parallel_groups": [
    ["FEAT-001", "FEAT-002", "FEAT-003"],
    ["FEAT-004"]
  ]
}
```

- `parallel_groups`: Items in the same group run concurrently. Different groups run sequentially.
- `depends_on`: Sub-tasks that must complete before this one starts.
- Group ordering follows dependency topology — independent items first, dependents last.

### Step 7: Summary & Single Dispatch Command

Print the summary table and a **single command** the user can copy-paste:

```
Work Plan Complete — "DuckDB schema cleanup"
──────────────────────────────────────────────
  FEAT-001  duckdb-frames-cleanup     ✓ open
  FEAT-002  duckdb-windows-cleanup    ✓ open
  FEAT-003  duckdb-enum-removal       ✓ open
  FEAT-004  duckdb-migration          ✓ open  (after 001, 002, 003)

Boundary: ✓ all independent
Parallel groups: 2
  Group 1: FEAT-001, FEAT-002, FEAT-003  (parallel)
  Group 2: FEAT-004                      (sequential)
──────────────────────────────────────────────

Next step — run this single command:

  bash codex-run.sh FEAT-001 FEAT-002 FEAT-003 FEAT-004

It will: check boundaries → link worktrees → run Codex in parallel (respecting dependencies) → monitor → print review command.
```
