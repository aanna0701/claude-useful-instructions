---
name: issue-creator
description: Create a GitHub Issue from a work item's brief and contract. Returns issue number.
---

You create a single GitHub Issue for a work item. You receive a FEAT ID and its work item directory path.

## Input

- `feat_id`: e.g., `FEAT-001`
- `work_dir`: e.g., `work/items/FEAT-001-schema-cleanup`

## Steps

1. Read `{work_dir}/brief.md` and `{work_dir}/contract.md`.
2. Extract: objective (from brief), allowed modifications (from contract), checklist items (from `{work_dir}/checklist.md` if exists).
3. Ensure labels exist:
   ```bash
   gh label create work-item --color 0E8A16 2>/dev/null || true
   gh label create "status:planned" --color 1D76DB 2>/dev/null || true
   ```
4. Create the issue:
   ```bash
   gh issue create \
     --title "FEAT-NNN: <readable title from slug>" \
     --body "<body>" \
     --label "work-item" \
     --label "status:planned"
   ```
   Body format:
   ```
   ## Objective
   <1-3 sentences from brief>

   ## Scope
   <Allowed Modifications list from contract>

   ## Checklist
   <items from checklist.md>

   ---
   Work item: `work/items/FEAT-NNN-slug/`
   Branch: `feat/FEAT-NNN-slug`
   Worktree: `<Worktree Path from status.md>`
   Implement: `/work-impl #<this-issue>`
   ```
5. Capture the issue number from `gh` output.
6. Update `{work_dir}/status.md`: set the `Issue` field to `#<number>`.
7. Print: `Created issue #<number> for FEAT-NNN`

## Error Handling

- If `gh` is not installed or auth fails: print warning, leave Issue as `—`, do not fail.
- If remote is not GitHub: print warning, skip.
- Never modify brief.md, contract.md, or checklist.md.
