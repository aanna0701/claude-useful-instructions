---
name: cursor-prompt-builder
description: Parse work item contract and brief, detect type from ID prefix, assemble Cursor prompts using type-specific templates, and generate .cursor/rules/.
---

Builds Cursor-ready prompts from work item artifacts. Detects type from ID prefix.

## Input

- `item_id`, `work_dir`, `mode` (`scaffold` or `verify`)

## Type Detection

| Prefix | Scaffold Template | Verify Template |
|--------|-------------------|-----------------|
| `FEAT`, `FIX`, `CHORE`, `PERF`, `TEST` | `scaffold-feat.md` | — (use /work-review) |
| `REFAC` | `scaffold-refactor.md` | — |
| `AUDIT`, `DOCS` | skip scaffold | `verify-audit.md` |

## Steps

### Parse Work Item

Read `brief.md` (objective, dependencies, scope) and `contract.md` (interfaces, boundaries, invariants, tests). AUDIT contracts: map "Audit Scope" → boundaries, "Audit Criteria" → interfaces, "Expected Output Format" → tests. If verify mode: also read `status.md` (branch, changed files, worktree path).

### scaffold mode

1. Skip AUDIT/DOCS with redirect to `/work-verify`
2. Select template by type. REFAC: parse `→` entries as migration pairs.
3. Fill variables. Infer `primary_language` from file extensions.
4. Derive glob patterns from allowed modifications and forbidden zones (dirs → append `**`)
5. Write `.cursor/rules/{SLUG}-guard.mdc` and `{SLUG}-forbidden.mdc` to worktree
6. Commit: `chore({SLUG}): add .cursor/rules/`

### verify mode (AUDIT/DOCS only)

1. Skip non-AUDIT with redirect to `/work-review`
2. Fill `verify-audit.md` template with scope and criteria

## Output

1. Rendered prompt in fenced code block (copy-paste ready)
2. `.cursor/rules/` files (scaffold mode, if worktree available)

## Error Handling

Missing brief/contract: fail. Empty fields: `[NOT SPECIFIED]`. Wrong status: warn, proceed. Failed `.cursor/rules/` write: print content instead. Never modify work item files.
