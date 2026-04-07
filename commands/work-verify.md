# work-verify — Generate Cursor Chat Verification Prompts

Generate Cursor Chat `@Codebase` verification prompts. Type is auto-detected from work item ID prefix.

---

## Input

**$ARGUMENTS**: Work item IDs (space-separated).

```
/work-verify FEAT-001
/work-verify FEAT-001 REFAC-002
/work-verify AUDIT-003          # → standalone audit (no prior implementation)
```

---

## Type → Behavior Matrix

| Type Prefix | Verification Focus | Template Used | Prerequisite Status |
|-------------|-------------------|---------------|---------------------|
| `FEAT`, `FIX`, `CHORE`, `PERF`, `TEST` | Interface compliance, boundary, type safety | `verify-feat.md` | `ready-for-review` |
| `REFAC` | Regression: dead imports, broken calls, config refs | `verify-refactor.md` | `ready-for-review` |
| `AUDIT`, `DOCS` | Codebase audit: patterns, naming, security, dead code | `verify-audit.md` | `planned` (no impl needed) |

---

## Execution Steps

### Step 1: Resolve Work Items

For each ID in `$ARGUMENTS`:

1. Locate `work/items/{ID}-*/` directory (glob match)
2. Read `status.md` from worktree (worktree-first resolution)
3. Verify status matches prerequisite:
   - FEAT/REFAC/FIX/CHORE/PERF/TEST: must be `ready-for-review` (warn if not)
   - AUDIT/DOCS: must be `planned` or `auditing` (no implementation phase)
4. Extract type prefix from ID

### Step 2: Generate Prompts (parallel per item)

Spawn `cursor-prompt-builder` agent for each item with `mode=verify`.

The agent:
1. Parses `brief.md`, `contract.md`, and `status.md`
2. Selects verification template based on type
3. Fills template variables (including Changed Files for non-AUDIT items)
4. Returns rendered prompt

### Step 3: Update Status (AUDIT only)

For AUDIT items:
- Update `status.md` → `Status = auditing`
- This is the terminal implementation step for AUDIT (no Codex dispatch)

### Step 4: Output

Print each prompt in a fenced code block with usage instruction:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FEAT-001 — Cursor Chat Verification Prompt
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

<rendered prompt here>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Copy the prompt above → Cursor Chat
🔍 Cursor will use @Codebase to check the full project
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

After all items, print next steps based on type:

For FEAT/REFAC (post-implementation verification):
```
Next Steps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Ingest Cursor results for auto-routing:
/work-verify-ingest {IDs}

# Or skip ingest and proceed directly:
/work-review {IDs}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

For AUDIT (standalone audit):
```
Next Steps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Ingest audit results:
/work-verify-ingest {IDs}
# → auto-routes to: create issues, plan fixes, or mark audited

# Or manually choose:
/work-plan --type=fix "Fix {audit objective} findings"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Error Handling

- Missing work item: `ERROR: {ID} not found in work/items/`
- Wrong status: `WARN: {ID} status is '{status}', expected '{expected}'. Proceeding anyway.`
- Missing Changed Files (non-AUDIT): `WARN: No changed files recorded in status.md. Verification may be incomplete.`
- AUDIT with no contract: `ERROR: {ID} missing contract.md — cannot generate audit criteria.`
