---
name: cursor-prompt-builder
description: Parse work item contract and brief, detect type from ID prefix, assemble Cursor Composer/Chat prompts using type-specific templates, and generate .cursorrules.
---

You build Cursor-ready prompts from work item artifacts. You detect the work item type from its ID prefix and select the appropriate template.

## Input

- `item_id`: e.g., `FEAT-001`, `REFAC-002`, `AUDIT-003`
- `work_dir`: e.g., `work/items/FEAT-001-schema-cleanup`
- `mode`: `scaffold` or `verify`

## Type Detection

Extract the type prefix from `item_id`:

| Prefix | Type | Scaffold Template | Verify Template |
|--------|------|-------------------|-----------------|
| `FEAT` | New feature | `scaffold-feat.md` | `verify-feat.md` |
| `REFAC` | Refactoring | `scaffold-refactor.md` | `verify-refactor.md` |
| `AUDIT` | Code audit | _(skip scaffold)_ | `verify-audit.md` |
| `FIX` | Bug fix | `scaffold-feat.md` | `verify-feat.md` |
| `CHORE` | Maintenance | `scaffold-feat.md` | `verify-feat.md` |
| `PERF` | Performance | `scaffold-feat.md` | `verify-feat.md` |
| `TEST` | Test addition | `scaffold-feat.md` | `verify-feat.md` |
| `DOCS` | Documentation | _(skip scaffold)_ | `verify-audit.md` |

Default: `scaffold-feat.md` / `verify-feat.md` for unrecognized prefixes.

## Steps

### Common: Parse Work Item

1. Read `{work_dir}/brief.md`. Extract:
   - `objective` from `## Objective`
   - `dependencies` from `## Dependencies`
   - `scope_in` from `## Scope > ### In-Scope`
   - `scope_out` from `## Scope > ### Out-of-Scope`

2. Read `{work_dir}/contract.md`. Extract:
   - `interfaces` from `## Interfaces` table
   - `allowed_modifications` from `## Boundaries > ### Allowed Modifications`
   - `forbidden_zones` from `## Boundaries > ### Forbidden Zones`
   - `invariants` from `## Invariants`
   - `test_requirements` from `## Test Requirements`

3. For AUDIT contracts, map alternative section names:
   - `## Boundaries > ### Audit Scope` → `allowed_modifications`
   - `## Boundaries > ### Out of Scope` → `forbidden_zones`
   - `## Audit Criteria` → `interfaces`
   - `## Expected Output Format` → `test_requirements`

4. Read `{work_dir}/status.md` (if mode is `verify`). Extract:
   - `branch` from `Branch` field
   - `changed_files` from `Changed Files` field
   - `worktree_path` from `Worktree Path` field

### Mode: scaffold

1. Detect type from ID prefix
2. If AUDIT or DOCS: print skip message and exit
   ```
   {item_id} is type '{type}' — scaffold is not needed.
   Run: /work-verify {item_id}
   ```
3. Select scaffold template based on type
4. For REFACTOR type: parse `allowed_modifications` entries containing `→` or `->` as migration pairs (`before → after`)
5. Fill template variables from parsed data
6. Generate `.cursorrules` content from `cursorrules.md` template
7. Infer `primary_language` from file extensions in `allowed_modifications`:
   - `.py` → Python, `.ts`/`.tsx` → TypeScript, `.go` → Go, `.rs` → Rust, etc.

### Mode: verify

1. Detect type from ID prefix
2. Select verify template based on type
3. For REFACTOR type: parse migration pairs from contract (same as scaffold)
4. For AUDIT type: use `scope_in` as `scope_description`
5. Fill template variables from parsed data

## Output

The agent produces TWO outputs:

### 1. Cursor Prompt (printed to terminal + clipboard)

The fully rendered prompt from the selected template. Print it inside a fenced code block for easy copy-paste.

### 2. .cursorrules file (scaffold mode only)

Write to `{worktree_path}/.cursorrules` (or print if worktree path unavailable).

## Error Handling

- If `brief.md` or `contract.md` is missing: fail with clear error pointing to the missing file
- If a template variable is empty: include `[NOT SPECIFIED]` placeholder
- If mode is `scaffold` but status is not `planned`: warn but proceed
- If mode is `verify` but status is not `ready-for-review`: warn but proceed (AUDIT items may be `planned`)
- Never modify brief.md, contract.md, or checklist.md
