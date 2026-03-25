# optimize-tokens — Analyze and reduce token waste in Claude Code instructions

Scan `.claude/` instruction files for token inefficiencies, report findings, and optionally apply fixes.

Target: $ARGUMENTS (if empty, scan all `.claude/` files)

---

## Step 1: Inventory

Collect all instruction files under `~/.claude/{commands,agents,skills,rules}`. Record `{path, line_count, type}`. Print inventory table with per-type totals and largest file.

## Step 2: Parallel analysis

Spawn 4 agents in parallel, passing the inventory to each:

| Agent | Responsibility |
|---|---|
| `token-duplication-detector` | Cross-file and intra-file duplication |
| `token-mcp-analyzer` | MCP call efficiency |
| `token-load-measurer` | Session token load and bloat |
| `token-split-detector` | Multi-responsibility files to split |

## Step 3: Report findings

Merge agent results. Print prioritized report: CRITICAL (>100 lines), MODERATE (20-100), LOW (<20). Include total lines, duplicate count, split candidates, recommended savings.

## Step 4: Apply fixes (with confirmation)

**Ask user:** "Found N optimizations saving ~M lines. Apply all / select / skip?"

Fix types: **Deletion**, **Compression**, **MCP merge**, **Split**.

**Rules:**
- NEVER remove content that exists only in one place
- NEVER compress agent identity/role sections
- NEVER merge MCP calls if it removes a fail-fast safety check
- NEVER split if resulting orchestrator exceeds 20 lines
- Always preserve installed `~/.claude/` copy in sync

## Step 5: Print summary

Files scanned, issues found, fixes applied, lines removed/added, net savings. List modified/deleted files.
