# work-verify — Codebase Audit (AUDIT type only)

Run codebase audits via Cursor/Antigravity. AUDIT items have no implementation phase — this IS the execution step. Optionally ingest results with `--ingest`.

For FEAT/REFAC verification, use `/work-review` directly — Claude reviews against the contract.

---

## Input

```
/work-verify AUDIT-001                     # Generate audit prompt for Cursor/Antigravity
/work-verify AUDIT-001 --ingest            # Parse Cursor/Antigravity output → verdict → route
/work-verify AUDIT-001 --ingest @file.md   # Read results from file
```

Non-AUDIT items are redirected:
```
/work-verify FEAT-001
# → "FEAT items don't need /work-verify. Next: /work-review FEAT-001"
```

---

## Phase 1: Generate Audit Prompt (default)

### Step 1: Resolve Work Items

For each ID in `$ARGUMENTS`:

1. Locate `work/items/{ID}-*/` directory (glob match)
2. If type prefix is NOT `AUDIT` or `DOCS`: print redirect message and skip
3. Read `status.md` — verify status is `planned` or `auditing`

### Step 2: Generate Prompts (parallel per item)

Spawn `cursor-prompt-builder` agent for each item with `mode=verify`.

The agent:
1. Parses `brief.md` and `contract.md`
2. Uses `verify-audit.md` template
3. Fills audit scope, criteria, and output format
4. Returns rendered prompt

### Step 3: Update Status

- Update `status.md` → `Status = auditing`

### Step 4: Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUDIT-001 — Cursor/Antigravity Audit Prompt
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

<rendered prompt here>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Copy the prompt above → Cursor/Antigravity Chat

After the AI responds, ingest the results:
  /work-verify AUDIT-001 --ingest
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 2: Ingest Results (`--ingest`)

### Step 1: Collect Output

1. If `$ARGUMENTS` contains a file path (starts with `@`): read that file
2. Otherwise: prompt user to paste Cursor/Antigravity output

### Step 2: Parse Findings

Parse the pasted output for structured findings. Accept these formats:

**Audit table format** (from verify-audit template):
```
| # | File | Line | Criterion | Issue | Severity | Suggested Fix |
|---|------|------|-----------|-------|----------|---------------|
```

**Freeform format** (fallback):
- Lines containing `CRITICAL`, `HIGH`, `MEDIUM`, `LOW` are parsed as findings

### Step 3: Write verify-result.md

Save parsed results to `work/items/{ID}-*/verify-result.md`:

```markdown
# Audit Result — {ID}

**Audited**: {timestamp}
**Source**: Cursor/Antigravity codebase audit
**Total findings**: {count}

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | {n} |
| HIGH     | {n} |
| MEDIUM   | {n} |
| LOW      | {n} |

## Findings

| # | File | Line | Criterion | Issue | Severity | Fix |
|---|------|------|-----------|-------|----------|-----|
{parsed findings rows}

## Verdict

{PASS / PASS_WITH_WARNINGS / FAIL}
```

### Step 4: Determine Verdict & Route

| Condition | Verdict | Action |
|-----------|---------|--------|
| 0 CRITICAL, 0 HIGH | `PASS` | Status → `audited` |
| 0 CRITICAL, 1+ HIGH | `PASS_WITH_WARNINGS` | Status → `audited`, print warnings |
| 1+ CRITICAL | `FAIL` | Status stays `auditing`, print action items |

### Step 5: Output

#### PASS / PASS_WITH_WARNINGS
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUDIT-001 — Audit Complete (audited)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Findings: {n} CRITICAL, {n} HIGH, {n} MEDIUM, {n} LOW
  Result saved: work/items/AUDIT-001-slug/verify-result.md

Options:
  /work-plan --type=fix "Fix AUDIT-001 findings"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### FAIL
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUDIT-001 — Audit FAILED (critical findings)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CRITICAL findings:
  1. src/auth/token.py:42 — SQL injection vulnerability

  Must address CRITICAL findings before closing audit.
  /work-plan --type=fix "Fix AUDIT-001 critical findings"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Error Handling

- Non-AUDIT item: `FEAT/REFAC items don't need /work-verify. Next: /work-review {ID}`
- Missing work item: `ERROR: {ID} not found in work/items/`
- Wrong status: `WARN: {ID} status is '{status}', expected 'planned' or 'auditing'.`
- Missing contract: `ERROR: {ID} missing contract.md — cannot generate audit criteria.`
- Empty paste: `WARN: No structured findings found. Saving raw output as verify-result.md.`
