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

**Running example** — "DuckDB schema cleanup" (removes dead columns from 3 tables + ENUMs):
```
FEAT-001  frames-column-cleanup   → src/models/frames.py      (independent)
FEAT-002  windows-column-cleanup  → src/models/windows.py     (independent)
FEAT-003  enum-removal            → src/schema/enums.py       (independent)
FEAT-004  schema-migration        → migrations/               (depends_on: 001-003)
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
Create slug from sub-task: lowercase, kebab-case, max 30 chars. Use consistent prefix for sibling FEATs (e.g., `FEAT-001-duckdb-frames-cleanup`).

### Step 4: Generate Work Items (parallel)

Spawn **parallel agents** (one per FEAT). Each agent:
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

Print a **boundary matrix** (✓ = independent, ⚠ = overlap, dep = dependency).

**If overlaps found:**
1. Print conflicting files and which FEATs touch them
2. Suggest: narrow one contract's boundaries, or merge the overlapping FEATs back into one
3. Ask user to confirm or adjust

### Step 6: Generate Dispatch Manifest

Create or update `work/dispatch.json` with fields: `batch_id`, `created`, `parent_topic`, `items` (array of `{feat_id, slug, status, depends_on, conflicts_with}`), and `parallel_groups` (array of arrays — same group = concurrent, different groups = sequential, topology-ordered).

### Step 7: Summary & Single Dispatch Command

Print summary table (FEAT IDs, slugs, statuses, boundary result, parallel groups) and a single copy-paste command:

```
bash codex-run.sh FEAT-001 FEAT-002 FEAT-003 FEAT-004
```
