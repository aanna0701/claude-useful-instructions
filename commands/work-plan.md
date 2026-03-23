# work-plan — Create Work Item for Claude-Codex Delegation

Create a complete work item bundle (brief + contract + checklist + status) for delegating implementation to Codex.

---

## Input

**$ARGUMENTS**: Feature topic, description, or path to source RFC/ADR.

If no arguments provided, ask:
> "What feature should I plan? Provide a topic or path to source RFC/ADR."

---

## Execution Steps

### Step 1: Gather Context

If `$ARGUMENTS` is a file path (RFC/ADR), read it for context.
Otherwise, ask the user for:
- **Objective**: What this work achieves (1-3 sentences)
- **Source**: Path to RFC/ADR (if not provided)
- **Scope**: What is in-scope vs out-of-scope
- **Boundaries**: Files/modules that may or may not be changed

### Step 2: Assign ID

```bash
# Find next FEAT number
ls work/items/ 2>/dev/null | grep -oP 'FEAT-\K\d+' | sort -n | tail -1
```

Assign next `FEAT-NNN` (3-digit, zero-padded). First item is `FEAT-001`.
Create slug from topic: lowercase, kebab-case, max 30 chars.
Create directory: `work/items/FEAT-NNN-slug/`

### Step 3: Summarize Design Docs (Gemini, optional)

If multiple source documents exist (RFC, ADR, references), call Gemini to compress:

```
gemini_summarize_design_pack(file_paths=["docs/rfc/RFC-012.md", "docs/adr/ADR-005.md", ...])
```

Use the summary as input for brief and contract generation.
**Skip if**: single source doc or no Gemini MCP available.

### Step 4: Generate Brief

**Preferred**: Spawn `doc-writer-task` agent with `bundle: true` and target directory.

**Fallback** (if agent not installed): Read template from `.claude/templates/work-item/brief.md`, fill in:
- Title, objective, source link, scope (in/out), dependencies

Write to `work/items/FEAT-NNN-slug/brief.md`

### Step 5: Generate Contract

**Option A (Gemini + Claude)**: Call Gemini for contract draft, then Claude reviews:
```
gemini_derive_contract(design_summary=<from step 3>, scope=<in/out>, boundaries=<allowed/forbidden>)
```
Claude reviews the draft, adjusts boundaries/invariants, and signs (status: draft → signed).

**Option B (agent)**: Spawn `doc-writer-contract` agent with `bundle: true`.

**Option C (template)**: Read template from `.claude/templates/work-item/contract.md`, fill manually.

Write to `work/items/FEAT-NNN-slug/contract.md`

### Step 6: Generate Checklist

**Preferred**: Spawn `doc-writer-checklist` agent with `bundle: true`.

**Fallback**: Read template from `.claude/templates/work-item/checklist.md`, fill in:
- Pre-conditions
- Verification items (Yes/No answerable, derived from contract)

Write to `work/items/FEAT-NNN-slug/checklist.md`

### Step 7: Initialize Status

Read template from `.claude/templates/work-item/status.md`.
Set: status=open, agent=TBD, branch=—.
Write to `work/items/FEAT-NNN-slug/status.md`

### Step 8: Output Codex Command

Print a ready-to-use Codex command:

```
## Codex Command

bash codex-implement.sh FEAT-NNN-slug
```

This script auto-reads brief → contract → checklist, initializes status to `in-progress`,
and prints structured implementation context for Codex.

If `codex-implement.sh` is not available in the target project, also print the manual fallback prompt:

```
Read in order:
1. work/items/FEAT-NNN-slug/brief.md
2. work/items/FEAT-NNN-slug/contract.md
3. work/items/FEAT-NNN-slug/checklist.md
Implement only what is required. Update status.md on every state change.
Branch: feat/FEAT-NNN-slug
```

### Step 9: Summary

Print a table of created files and next steps:

| File | Status |
|------|--------|
| brief.md | Created |
| contract.md | Created |
| checklist.md | Created |
| status.md | Created |

**Next**: Copy the Codex prompt above and paste it into a Codex session.
