# Cursor Chat Verification Prompt — FEAT (Implementation Check)

Use this template to generate a Cursor Chat prompt for verifying new feature implementations.

---

## Template

```
@Codebase

## Implementation Verification: {{objective}}

Work Item: {{feat_id}}
Branch: {{branch}}

### Changed Files

{{#each changed_files}}
- {{this}}
{{/each}}

### Verification Checklist

1. **Interface compliance**: Do the changed files implement ALL interfaces from the contract?
{{#each interfaces}}
   - [ ] `{{name}}` ({{type}}) in `{{owner}}`: {{spec}}
{{/each}}

2. **Boundary violation**: Confirm these files were NOT modified:
{{#each forbidden_zones}}
   - [ ] `{{path}}` — untouched
{{/each}}

3. **Dependency conflict**: Check for:
   - [ ] No circular imports involving the changed files
   - [ ] No naming collisions with existing exports
   - [ ] No duplicate type definitions

4. **Type safety**: Verify:
   - [ ] New types are compatible with existing type system
   - [ ] No `any` / untyped escape hatches introduced
   - [ ] Generic constraints are properly bounded

5. **Invariant compliance**:
{{#each invariants}}
   - [ ] {{this}}
{{/each}}

6. **Test coverage**:
{{#each test_requirements}}
   - [ ] {{this}}
{{/each}}

### Report Format

For each issue found:
| File | Line | Issue | Severity |
|------|------|-------|----------|
```

## Variable Sources

| Variable | Source File | Section |
|----------|------------|---------|
| `objective` | `brief.md` | `## Objective` |
| `feat_id` | work item ID | e.g., `FEAT-001` |
| `branch` | `status.md` | `Branch` field |
| `changed_files` | `status.md` | `Changed Files` field |
| `interfaces` | `contract.md` | `## Interfaces` |
| `forbidden_zones` | `contract.md` | `## Boundaries > ### Forbidden Zones` |
| `invariants` | `contract.md` | `## Invariants` |
| `test_requirements` | `contract.md` | `## Test Requirements` |
