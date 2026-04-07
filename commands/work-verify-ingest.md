# work-verify-ingest — Parse Cursor Verification Results

Ingest Cursor Chat verification output, parse findings, and route to next action (status transition, issue creation, or revision).

---

## Input

**$ARGUMENTS**: Work item ID followed by the verification result (pasted inline or as a file path).

```
/work-verify-ingest FEAT-001
# → prompts user to paste Cursor output

/work-verify-ingest FEAT-001 @path/to/verify-output.md
# → reads file directly
```

---

## Execution Steps

### Step 1: Collect Verification Output

1. If `$ARGUMENTS` contains a file path (starts with `@`): read that file
2. Otherwise: prompt user to paste Cursor Chat output, terminated by an empty line or EOF

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
| 1 | src/auth/token.py | 42 | Security | SQL injection | CRITICAL | Use parameterized queries |
```

**Freeform format** (fallback):
- Lines containing `CRITICAL`, `HIGH`, `MEDIUM`, `LOW` are parsed as findings
- Lines starting with `- [ ]` or `- [x]` are parsed as checklist items

Extract for each finding:
- `file`: file path
- `line`: line number (optional)
- `issue`: description
- `severity`: CRITICAL / HIGH / MEDIUM / LOW
- `criterion`: audit criterion name (AUDIT only)
- `suggested_fix`: fix description (optional)

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

{auto-determined: PASS / PASS_WITH_WARNINGS / FAIL}
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
  Findings: 0 CRITICAL, {n} HIGH, {n} MEDIUM, {n} LOW

  HIGH findings:
  1. src/auth/token.py:42 — Missing null check
  2. ...

  Result saved: work/items/FEAT-001-slug/verify-result.md

Options:
  # Proceed to review (HIGH findings noted but acceptable):
  /work-review FEAT-001

  # Fix findings first:
  /work-revise FEAT-001
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### FAIL
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FEAT-001 — Verification FAILED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Findings: {n} CRITICAL, {n} HIGH, {n} MEDIUM, {n} LOW

  CRITICAL findings:
  1. src/auth/token.py:42 — SQL injection vulnerability
  2. ...

  Result saved: work/items/FEAT-001-slug/verify-result.md

Next: /work-revise FEAT-001
  (CRITICAL findings must be resolved before review)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### AUDIT — PASS (creates issues)
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUDIT-003 — Audit Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Findings: 0 CRITICAL, 0 HIGH, {n} MEDIUM, {n} LOW
  Status: audited
  Result saved: work/items/AUDIT-003-slug/verify-result.md

Options:
  # Create GitHub issues from findings:
  # (spawn issue-creator agent with verify-result.md)

  # Plan fix work items:
  /work-plan --type=fix "Fix AUDIT-003 findings"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Error Handling

- Missing work item: `ERROR: {ID} not found in work/items/`
- Empty paste / no findings parsed: `WARN: No structured findings found. Saving raw output as verify-result.md.`
- Already has verify-result.md: overwrite with timestamp backup (`verify-result.md.bak.{timestamp}`)
