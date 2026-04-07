# Cursor/Antigravity Composer Prompt — FEAT (New Feature)

Use this template to generate a Cursor/Antigravity Composer prompt for scaffolding new feature files.

---

## Template

```
## Objective

{{objective}}

## Files to Create/Modify

{{#each allowed_modifications}}
- {{this}}
{{/each}}

## Interfaces & Types

{{#each interfaces}}
| {{name}} | {{type}} | {{owner}} | {{spec}} |
{{/each}}

## Dependencies

{{#each dependencies}}
- {{this}}
{{/each}}

## Constraints

Do NOT modify these files:
{{#each forbidden_zones}}
- {{path}} — {{reason}}
{{/each}}

## Expected Output

For each file listed above:
1. Create the directory structure if it doesn't exist
2. Define types/interfaces referenced in the Interfaces table
3. Write function signatures with TODO stub bodies
4. Add all necessary import statements
5. Include module-level docstring describing the file's purpose

Do NOT implement business logic — only create the skeleton.
Mark every unimplemented body with: `# TODO({{feat_id}}): implement`
```

## Variable Sources

| Variable | Source File | Section |
|----------|------------|---------|
| `objective` | `brief.md` | `## Objective` |
| `allowed_modifications` | `contract.md` | `## Boundaries > ### Allowed Modifications` |
| `interfaces` | `contract.md` | `## Interfaces` |
| `dependencies` | `brief.md` | `## Dependencies` |
| `forbidden_zones` | `contract.md` | `## Boundaries > ### Forbidden Zones` |
| `feat_id` | work item ID | e.g., `FEAT-001` |
