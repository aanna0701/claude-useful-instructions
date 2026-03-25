# optimize-tokens — Analyze and reduce token waste in Claude Code instructions

Scan `.claude/` instruction files (commands, agents, skills, rules) for token inefficiencies, report findings, and optionally apply fixes.

Target: $ARGUMENTS (if empty, scan all `.claude/` files)

---

## Step 1: Inventory (parallel)

Collect all instruction files under `~/.claude/{commands,agents,skills,rules}`. Record `path`, `line_count`, `type`. Print inventory table with per-type totals and largest file.

---

## Step 2: Detect duplication (cross-file analysis)

### 2.1 Command ↔ Agent duplication
For each command delegating to agents: compare content blocks, flag >70% text overlap.
**Pattern:** Command embeds agent instructions AND tells to Read a reference that duplicates the agent.

### 2.2 Reference ↔ Agent duplication
Compare `skills/*/references/` files against agent files. Flag >80% overlap.
**Highest-value targets** — reference loaded via Read AND agent loaded on spawn = double loading.

### 2.3 Intra-file repetition
Same rule in multiple sections, verbose examples replaceable by compact tables, redundant output templates.

### 2.4 Cross-file rule repetition
Rules in `rules/*.md` repeated verbatim in agent/command files — should reference, not duplicate.

---

## Step 3: Analyze MCP call efficiency

For commands/skills using MCP tools:
1. **Map all MCP call points** (stage, action, tool, count)
2. **Detect inefficiencies**: redundant queries, context-replaceable queries, missing batch opportunities, upload-then-requery
3. **Session boundary**: verify calls respect session splits (persist before split, retrieve after)

---

## Step 4: Measure token load per session

1. **Trace execution paths**: for each command, list all files loaded (command + Read + agent spawns) with line counts
2. **Flag bloat**: single command >150 lines, session >500 lines, file loaded twice, agent >100 lines

---

## Step 5: Report findings

Print prioritized report: CRITICAL (>100 lines), MODERATE (20-100), LOW (<20), MCP efficiency. Include summary with total lines, duplicate count, recommended savings.

---

## Step 6: Apply fixes (with confirmation)

**Ask user:** "Found N optimizations saving ~M lines. Apply all / select / skip?"

Fix types:
- **Deletion**: verify no other references, delete file, update Read references
- **Compression**: remove duplicated sections, replace with references
- **MCP**: merge redundant calls (preserve fail-fast safety checks)

**Rules:**
- NEVER remove content that exists only in one place
- NEVER compress agent identity/role sections
- NEVER merge MCP calls if it removes a fail-fast safety check
- Always preserve installed `~/.claude/` copy in sync

---

## Step 7: Print summary

Files scanned, issues found, fixes applied, lines removed/added, net savings, MCP call changes. List modified/deleted files.
