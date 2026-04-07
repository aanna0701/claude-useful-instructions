# Cursor/Antigravity Verification Prompt — AUDIT (Codebase Audit)

Use this template to generate a Cursor/Antigravity prompt for standalone codebase audits.
AUDIT items skip scaffold and Codex — this prompt runs directly after `/work-plan`.

---

## Template

```
@Codebase

## Code Audit: {{objective}}

Work Item: {{audit_id}}
Audit Scope: {{scope_description}}

### Files/Directories in Scope

{{#each audit_scope}}
- {{this}}
{{/each}}

### Out of Scope

{{#each out_of_scope}}
- {{this}}
{{/each}}

### Audit Criteria

{{#each audit_criteria}}
{{@index_1}}. **{{name}}**: {{description}}
   - Pass condition: {{pass_condition}}
   - Examples of violation: {{violation_examples}}
{{/each}}

### Instructions

For each file in scope:
1. Check against ALL audit criteria above
2. Record every violation found
3. Classify severity: CRITICAL / HIGH / MEDIUM / LOW
4. Suggest a fix for each violation (one-line description)

### Output Format

#### Summary
- Total files scanned: N
- Files with violations: N
- Violations by severity: CRITICAL: N, HIGH: N, MEDIUM: N, LOW: N

#### Violations

| # | File | Line | Criterion | Issue | Severity | Suggested Fix |
|---|------|------|-----------|-------|----------|---------------|

#### Recommendations
1. [Top-priority fix recommendation]
2. [Second priority]
3. [...]
```

## Variable Sources

| Variable | Source File | Section |
|----------|------------|---------|
| `objective` | `brief.md` | `## Objective` |
| `audit_id` | work item ID | e.g., `AUDIT-001` |
| `scope_description` | `brief.md` | `## Scope > ### In-Scope` (summarized) |
| `audit_scope` | `contract.md` | `## Boundaries > ### Audit Scope` (replaces Allowed Modifications) |
| `out_of_scope` | `contract.md` | `## Boundaries > ### Out of Scope` (replaces Forbidden Zones) |
| `audit_criteria` | `contract.md` | `## Audit Criteria` (replaces Interfaces) |

## Notes

- AUDIT contracts use different section names than FEAT/REFACTOR contracts
- The `cursor-prompt-builder` agent handles the section name mapping automatically
- AUDIT items do not require `status.md` Changed Files (no implementation phase)
- Results can be converted to GitHub Issues via `issue-creator` agent
