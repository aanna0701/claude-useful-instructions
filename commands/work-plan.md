# work-plan — Create Work Items for Claude-Codex Delegation

Create work item bundles (brief + contract + checklist + status) for delegating implementation to Codex. Supports single or multiple topics — multiple topics are planned in parallel with automatic boundary conflict detection.

---

## Input

**$ARGUMENTS**: One or more feature topics (newline-separated), or a path to a source RFC/ADR.

If no arguments provided, ask:
> "What feature(s) should I plan? Provide topic(s) or path to source RFC/ADR."

Single topic example:
```
/work-plan Add JWT auth middleware
```

Multiple topics example:
```
/work-plan
DuckDB schema cleanup
Add JWT auth middleware
Refactor logging pipeline
```

---

## Execution Steps

### Step 1: Parse Input & Gather Context

**Single topic**: If `$ARGUMENTS` is one line or a file path, treat as a single work item.
**Multiple topics**: If `$ARGUMENTS` has multiple lines, treat each line as a separate work item.

For each topic, gather or infer:
- **Objective**: What this work achieves (1-3 sentences)
- **Source**: Path to RFC/ADR (if available)
- **Scope**: What is in-scope vs out-of-scope
- **Boundaries**: Files/modules that may or may not be changed

For multiple topics, ask the user once for shared context (e.g., "All related to the data pipeline refactor"), then gather per-topic specifics.

### Step 2: Assign IDs

```bash
# Find next FEAT number
ls work/items/ 2>/dev/null | grep -oP 'FEAT-\K\d+' | sort -n | tail -1
```

Assign sequential `FEAT-NNN` (3-digit, zero-padded). First item is `FEAT-001`.
Create slug from topic: lowercase, kebab-case, max 30 chars.

### Step 3: Summarize Design Docs (Gemini, optional)

If multiple source documents exist (RFC, ADR, references), call Gemini to compress:

```
gemini_summarize_design_pack(file_paths=["docs/rfc/RFC-012.md", "docs/adr/ADR-005.md", ...])
```

Use the summary as input for brief and contract generation.
**Skip if**: single source doc or no Gemini MCP available.

### Step 4: Generate Work Items

**Single topic**: Generate brief → contract → checklist → status sequentially (same as before).

**Multiple topics**: Spawn **parallel agents**, one per topic:
```
Agent 1: Generate FEAT-001 (brief + contract + checklist + status)
Agent 2: Generate FEAT-002 (brief + contract + checklist + status)
Agent 3: Generate FEAT-003 (brief + contract + checklist + status)
```

Each agent:
1. **Generate Brief** — Spawn `doc-writer-task` agent with `bundle: true`, or fill from `.claude/templates/work-item/brief.md`
2. **Generate Contract** — Call `gemini_derive_contract` for draft → Claude signs, or spawn `doc-writer-contract`, or fill template
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
          FEAT-001    FEAT-002    FEAT-003
FEAT-001     —           ✓           ✓
FEAT-002     ✓           —           ⚠ OVERLAP
FEAT-003     ✓           ⚠ OVERLAP   —

⚠ FEAT-002 × FEAT-003: both modify src/utils/logger.py
──────────────────────────────────────────────
```

**If overlaps found:**
1. Print conflicting files and which FEATs touch them
2. Suggest: narrow one contract's boundaries, or mark as sequential
3. Ask user to confirm or adjust

**If clean:** Print `✓ All boundaries independent — safe for parallel dispatch`

### Step 6: Generate Dispatch Manifest

Create or update `work/dispatch.json`:

```json
{
  "batch_id": "BATCH-YYYYMMDD-HHMM",
  "created": "YYYY-MM-DD HH:MM",
  "items": [
    {
      "feat_id": "FEAT-001",
      "slug": "FEAT-001-duckdb-schema-cleanup",
      "status": "open",
      "depends_on": [],
      "conflicts_with": []
    }
  ],
  "parallel_groups": [
    ["FEAT-001", "FEAT-002"],
    ["FEAT-003"]
  ]
}
```

- `parallel_groups`: Items in the same group can run concurrently. Different groups run sequentially.
- `conflicts_with`: Populated from boundary overlap check.
- `depends_on`: Set by user if explicit ordering needed.

**Single item**: Still generates dispatch.json (group of 1). This keeps the interface consistent.

### Step 7: Summary & Single Dispatch Command

Print the summary table and a **single command** the user can copy-paste:

```
Work Plan Complete
──────────────────────────────────────────────
  FEAT-001  duckdb-schema-cleanup      ✓ open
  FEAT-002  jwt-auth-middleware        ✓ open
  FEAT-003  refactor-logging           ✓ open

Boundary: ✓ all independent  (or: ⚠ 1 overlap, grouped sequentially)
Dispatch: work/dispatch.json
──────────────────────────────────────────────

Next step — run this single command:

  bash codex-dispatch.sh FEAT-001 FEAT-002 FEAT-003

It will: check boundaries → link worktrees → run Codex in parallel → monitor → print review command.
```

The dispatch script handles everything — worktree linking, boundary validation, parallel `codex exec`, completion monitoring, and outputting the `/work-review` command when all items finish. The user only needs to paste this one command.
