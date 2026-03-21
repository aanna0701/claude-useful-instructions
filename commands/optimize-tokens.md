# optimize-tokens — Analyze and reduce token waste in Claude Code instructions

Scan `.claude/` instruction files (commands, agents, skills, rules) for token inefficiencies, report findings, and optionally apply fixes.

Target: $ARGUMENTS (if empty, scan all `.claude/` files)

---

## Step 1: Inventory (parallel)

Collect all instruction files and measure their size:

```bash
# Run in parallel
find ~/.claude/commands -name "*.md" | head -50
find ~/.claude/agents -name "*.md" | head -50
find ~/.claude/skills -name "*.md" | head -50
find ~/.claude/rules -name "*.md" | head -50
```

For each file, record: `path`, `line_count`, `type` (command/agent/skill/rule/reference).

Print inventory table:
```
Token Inventory
──────────────────────────────────────────────
Type        Files   Lines   Largest file
command     5       450     cover-letter.md (143)
agent       14      820     cover-letter-reviewer.md (97)
skill       3       380     diataxis-doc-system.md (120)
rule        2       160     vla-code-standards.md (90)
reference   8       520     parallelism.md (75)
──────────────────────────────────────────────
Total       32      2330
```

---

## Step 2: Detect duplication (cross-file analysis)

### 2.1 Command ↔ Agent duplication

For each command that delegates to agents (`cover-letter-writer`, `doc-writer-*`, etc.):
1. Read the command file
2. Read each referenced agent file
3. Compare content blocks — flag sections with >70% text overlap

**Pattern:** Command summarizes agent instructions AND tells to `Read` a reference file that duplicates the agent.

### 2.2 Reference ↔ Agent duplication

For each file in `commands/references/` or `skills/*/references/`:
1. Compare against all agent files
2. Flag files with >80% content overlap with an agent definition

**These are the highest-value targets** — reference files loaded via `Read` AND agent files loaded on spawn = double loading.

### 2.3 Intra-file repetition

Within each file, detect:
- Same rule stated in different sections (e.g., "과장 금지" in Identity, Style Rules, and Global Rules)
- Output format templates that could be shorter
- Verbose examples where a compact table would suffice

### 2.4 Cross-file rule repetition

Rules stated in `rules/*.md` that are repeated verbatim in agent/command files:
- Coding style rules copy-pasted into agents
- Security rules restated in commands
- These should reference the rule file, not duplicate content

---

## Step 3: Analyze MCP call efficiency

For each command/skill that uses MCP tools (NotebookLM, Exa, GitHub, etc.):

### 3.1 Map all MCP call points

Build a call map:
```
MCP Call Map: /cover-letter
──────────────────────────────────────────────
#   Stage       Action          Tool            Count
1   Stage 1     Cross-analysis  nlm query       4
2   Stage 1     Structured      nlm query       3
...
──────────────────────────────────────────────
Total calls: 14
```

### 3.2 Detect inefficiencies

Flag these patterns:
- **Redundant queries**: Same information requested in different stages
- **Queries replaceable by context**: Data already in conversation context being re-queried from MCP
- **Missing batch opportunities**: Multiple sequential calls that could be a single compound query
- **Unnecessary validation calls**: Existence checks that could be deferred to the next real query
- **Upload-then-immediately-query**: Uploading data and querying it back in the same session (data is already in context)

### 3.3 Session boundary analysis

Check if MCP calls respect session splits:
- Calls before session split should upload results for persistence
- Calls after session split should retrieve, not re-derive
- Flag any call that re-derives data already uploaded in a prior stage

---

## Step 4: Measure token load per session

Simulate a full execution path and calculate total tokens loaded:

### 4.1 Trace execution paths

For each command, trace what gets loaded:
```
Session trace: /cover-letter (Stage 1/2)
──────────────────────────────────────────────
1. cover-letter.md                    103 lines  (command load)
2. Read stage1-context-extraction.md   47 lines  (explicit Read)
3. Read stage2-career-docs.md          35 lines  (explicit Read)
──────────────────────────────────────────────
Total: 185 lines

Session trace: /cover-letter (Stage 3)
──────────────────────────────────────────────
1. cover-letter.md                    103 lines  (command load)
2. cover-letter-writer.md agent        66 lines  (agent spawn ×1)
3. cover-letter-reviewer.md agent      97 lines  (agent spawn ×3-5)
──────────────────────────────────────────────
Total: 460-660 lines (depending on iterations)
```

### 4.2 Identify bloat

Flag sessions exceeding these thresholds:
- Single command load > 150 lines
- Total session load > 500 lines
- Any file loaded more than once per session
- Agent file > 100 lines (agents should be focused)

---

## Step 5: Report findings

Print a prioritized report:

```
Token Optimization Report
══════════════════════════════════════════════

🔴 CRITICAL (>100 lines savings)
  #1  references/writer-prompt.md duplicates agents/cover-letter-writer.md
      Action: Delete reference, update command to delegate to agent
      Savings: ~60 lines

🟡 MODERATE (20-100 lines savings)
  #2  cover-letter.md Global Rules repeats agent-level rules
      Action: Keep only orchestration-level rules
      Savings: ~30 lines

🟢 LOW (<20 lines savings)
  #3  stage2-career-docs.md repeats session split message from cover-letter.md
      Action: Replace with reference to parent command
      Savings: ~5 lines

📡 MCP EFFICIENCY
  ✅ No redundant MCP calls detected
  ⚠️ Stage Gate check could merge with Writer's first query (saves 1 call)
     Recommendation: Keep as-is (fail-fast safety outweighs 1 call)

📊 SUMMARY
──────────────────────────────────────────────
Total instruction lines:    2330
Duplicate lines found:      ~210 (9%)
Recommended savings:        ~195 lines (8.4%)
MCP calls (optimal/current): 13/14
──────────────────────────────────────────────
```

---

## Step 6: Apply fixes (with confirmation)

**Ask user before applying:** "Found N optimizations saving ~M lines. Apply all / select individually / skip?"

For each approved fix:

### Deletion fixes
1. Verify the duplicate file is not referenced from other commands/agents
2. Delete the file
3. Update any `Read` references in parent commands
4. Delete from installed `~/.claude/` location too

### Compression fixes
1. Read the target file
2. Remove duplicated sections, replace with references or single-line delegations
3. Verify the compressed file still contains all orchestration logic

### MCP fixes
1. Document the current call count
2. Apply the optimization (merge calls, remove redundant queries)
3. Add comment noting the optimization for future maintainers

**Rules:**
- NEVER remove content that exists only in one place
- NEVER compress agent identity/role sections (these define behavior)
- NEVER merge MCP calls if it removes a fail-fast safety check
- Always preserve the installed `~/.claude/` copy in sync

---

## Step 7: Print summary

```
Token optimization complete
──────────────────────────────────────────────
Files scanned:    32
Issues found:     5 (2 critical, 2 moderate, 1 low)
Fixes applied:    4
Lines removed:    195
Lines added:      12
Net savings:      183 lines (7.9%)
MCP calls:        unchanged (14) — safety trade-off preserved

Changes:
  deleted   commands/references/writer-prompt.md
  deleted   commands/references/reviewer-prompt.md
  modified  commands/cover-letter.md (-60 lines)
  modified  commands/references/stage2-career-docs.md (-5 lines)
──────────────────────────────────────────────
Next: review changes, then /smart-git-commit-push
```
