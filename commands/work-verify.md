# work-verify — Cursor Verification (Prompt + Result Ingest)

Generate Cursor Chat `@Codebase` verification prompts, then optionally ingest the results for auto-routing. Two modes in one command.

---

## Input

```
/work-verify FEAT-001                     # Phase 1: generate verification prompt
/work-verify FEAT-001 --ingest            # Phase 2: paste Cursor output → parse → route
/work-verify FEAT-001 --ingest @file.md   # Phase 2: read results from file
```

---

## Type → Behavior Matrix

| Type Prefix | Verification Focus | Template Used | Prerequisite Status |
|-------------|-------------------|---------------|---------------------|
| `FEAT`, `FIX`, `CHORE`, `PERF`, `TEST` | Interface compliance, boundary, type safety | `verify-feat.md` | `ready-for-review` |
| `REFAC` | Regression: dead imports, broken calls, config refs | `verify-refactor.md` | `ready-for-review` |
| `AUDIT`, `DOCS` | Codebase audit: patterns, naming, security, dead code | `verify-audit.md` | `planned` (no impl needed) |

---

## Phase 1: Generate Prompt (default)

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

### Step 4: Output

Print each prompt in a fenced code block:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FEAT-001 — Cursor Chat Verification Prompt
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

<rendered prompt here>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Copy the prompt above → Cursor Chat
Cursor will use @Codebase to check the full project

After Cursor responds, ingest the results:
  /work-verify {IDs} --ingest

Or skip and proceed directly:
  /work-review {IDs}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 2: Ingest Results (`--ingest`)

### Step 1: Collect Verification Output

1. If `$ARGUMENTS` contains a file path (starts with `@`): read that file
2. Otherwise: prompt user to paste Cursor Chat output

### Step 2: Resolve Work Item

1. Locate `work/items/{ID}-*/` directory (glob match)
2. Read `status.md` from worktree (worktree-first resolution)
3. Extract type prefix from ID

### Step 3: Parse Findings

Parse the pasted output for structured findings. Accept these formats:

**Table format** (from verify-feat/verify-refactor templates):
```
| File | Line | Issue | Severity |
|------|------|-------|----------|
| src/auth/token.py | 42 | Missing null check | HIGH |
```

**Audit table format** (from verify-audit template):
```
| # | File | Line | Criterion | Issue | Severity | Suggested Fix |
|---|------|------|-----------|-------|----------|---------------|
```

**Freeform format** (fallback):
- Lines containing `CRITICAL`, `HIGH`, `MEDIUM`, `LOW` are parsed as findings
- Lines starting with `- [ ]` or `- [x]` are parsed as checklist items

### Step 4: Write verify-result.md

Save parsed results to `work/items/{ID}-*/verify-result.md`:

```markdown
# Verification Result — {ID}

**Verified**: {timestamp}
**Source**: Cursor Chat @Codebase
**Total findings**: {count}

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | {n} |
| HIGH     | {n} |
| MEDIUM   | {n} |
| LOW      | {n} |

## Findings

| # | File | Line | Issue | Severity | Fix |
|---|------|------|-------|----------|-----|
{parsed findings rows}

## Verdict

{PASS / PASS_WITH_WARNINGS / FAIL}
```

### Step 5: Determine Verdict & Route

| Condition | Verdict | Action |
|-----------|---------|--------|
| 0 CRITICAL, 0 HIGH | `PASS` | Status → `ready-for-review` (FEAT/REFAC) or `audited` (AUDIT) |
| 0 CRITICAL, 1+ HIGH | `PASS_WITH_WARNINGS` | Print warnings, ask user to proceed or revise |
| 1+ CRITICAL | `FAIL` | Status stays, print revision instructions |

### Step 6: Output

#### PASS
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FEAT-001 — Verification PASSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Findings: 0 CRITICAL, 0 HIGH, {n} MEDIUM, {n} LOW
  Result saved: work/items/FEAT-001-slug/verify-result.md

Next: /work-review FEAT-001
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### PASS_WITH_WARNINGS
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FEAT-001 — Verification PASSED with warnings
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  HIGH findings:
  1. src/auth/token.py:42 — Missing null check

Options:
  /work-review FEAT-001       # proceed (warnings noted)
  /work-revise FEAT-001       # fix first
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### FAIL
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FEAT-001 — Verification FAILED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CRITICAL findings:
  1. src/auth/token.py:42 — SQL injection vulnerability

Next: /work-revise FEAT-001
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### AUDIT — PASS
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUDIT-003 — Audit Complete (audited)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Options:
  /work-plan --type=fix "Fix AUDIT-003 findings"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Error Handling

- Missing work item: `ERROR: {ID} not found in work/items/`
- Wrong status: `WARN: {ID} status is '{status}', expected '{expected}'. Proceeding anyway.`
- Missing Changed Files (non-AUDIT): `WARN: No changed files recorded in status.md.`
- AUDIT with no contract: `ERROR: {ID} missing contract.md`
- Empty paste / no findings parsed: `WARN: No structured findings found. Saving raw output as verify-result.md.`
- Already has verify-result.md: overwrite with timestamp backup
