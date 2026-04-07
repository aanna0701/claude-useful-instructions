# Cursor Chat Verification Prompt — REFACTOR (Regression Check)

Use this template to generate a Cursor Chat prompt for verifying refactoring didn't break anything.

---

## Template

```
@Codebase

## Regression Verification: {{objective}}

Work Item: {{feat_id}}
Branch: {{branch}}

### Changed Files

{{#each changed_files}}
- {{this}}
{{/each}}

### Regression Checklist

1. **Dead imports**: Search the entire codebase for imports referencing OLD paths:
{{#each migration_entries}}
   - [ ] No remaining imports from `{{before}}` (should now use `{{after}}`)
{{/each}}

2. **Broken calls**: Verify all callers of moved symbols are updated:
{{#each affected_references}}
   - [ ] `{{file}}` → `{{symbol}}` now imports from correct path
{{/each}}

3. **Re-export coverage**: If moved modules had barrel exports:
   - [ ] Index/barrel files updated or deprecation re-exports added
   - [ ] No external consumers broken by the move

4. **Test path references**: Verify tests reference new paths:
   - [ ] Test imports updated to new module locations
   - [ ] Test fixtures/mocks reference correct paths
   - [ ] No hardcoded old paths in test configuration

5. **Config references**: Check project configuration files:
   - [ ] tsconfig.json paths / Python pyproject.toml / Go module paths updated
   - [ ] package.json exports (if applicable) reflect new structure
   - [ ] CI/CD scripts reference correct paths
   - [ ] Documentation references updated

6. **Behavioral equivalence**:
   - [ ] Public API signatures unchanged (no breaking changes)
   - [ ] Return types and error types preserved
   - [ ] Side effects (logging, metrics) maintained

### Report Format

For each issue found:
| File | Line | Issue | Severity |
|------|------|-------|----------|
```

## Variable Sources

| Variable | Source File | Section |
|----------|------------|---------|
| `objective` | `brief.md` | `## Objective` |
| `feat_id` | work item ID | e.g., `REFAC-001` |
| `branch` | `status.md` | `Branch` field |
| `changed_files` | `status.md` | `Changed Files` field |
| `migration_entries` | `contract.md` | `## Boundaries > ### Allowed Modifications` (parsed as before→after) |
| `affected_references` | `contract.md` | `## Interfaces` |
