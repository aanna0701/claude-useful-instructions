# Cursor/Antigravity Composer Prompt — REFACTOR (Code Restructuring)

Use this template to generate a Cursor/Antigravity Composer prompt for refactoring operations.

---

## Template

```
## Objective

{{objective}}

## Migration Map

| Before (current path) | After (new path) | Change Type |
|-----------------------|-------------------|-------------|
{{#each migration_entries}}
| {{before}} | {{after}} | {{change_type}} |
{{/each}}

## Affected References

These files import or call the modules being moved:
{{#each affected_references}}
- {{file}}: imports `{{symbol}}` from `{{old_path}}`
{{/each}}

## Constraints

Do NOT modify these files:
{{#each forbidden_zones}}
- {{path}} — {{reason}}
{{/each}}

Preserve existing public API signatures — no breaking changes.

## Expected Output

1. Move/rename files according to the Migration Map
2. Update ALL import paths in Affected References
3. Update re-exports if the module had a barrel/index file
4. Update config references (tsconfig paths, package.json exports, pyproject.toml, etc.)
5. Do NOT change function signatures, class interfaces, or behavior
6. If a moved module was re-exported from an index file, add a deprecation re-export:
   `// @deprecated — moved to {{new_path}}, remove after next release`
```

## Variable Sources

| Variable | Source File | Section |
|----------|------------|---------|
| `objective` | `brief.md` | `## Objective` |
| `migration_entries` | `contract.md` | `## Boundaries > ### Allowed Modifications` (parsed as before→after pairs) |
| `affected_references` | `contract.md` | `## Interfaces` (import/call relationships) |
| `forbidden_zones` | `contract.md` | `## Boundaries > ### Forbidden Zones` |

## Notes

- `change_type` values: `move`, `rename`, `split`, `merge`
- The agent parses "Allowed Modifications" entries that contain `→` or `->` as migration pairs
- Entries without arrows are treated as in-place refactors (same path, internal restructure)
