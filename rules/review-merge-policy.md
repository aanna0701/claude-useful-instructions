# Review and Merge Policy

## Merge Gating

Before any merge:
1. Read work item metadata (contract Branch Map section) for declared merge target.
2. Confirm parent freshness — branch must include all parent commits.
3. Confirm required CI checks are green (if `require_green_ci` is set in branch-map.yaml).
4. Confirm no unresolved MUST-fix items remain in review.md.
5. Use declared `merge_target`, never a hardcoded branch name.

## After Merge

- Ask user confirmation if `ask_confirm_before_merge` is true.
- Delete feature branch only if `delete_branch_after_merge` is true.
- If design/contract changes were made, check whether sibling open work items need sync.

## Review Failure

- Write explicit MUST-fix items to review.md.
- Preserve branch metadata for the next iteration.
- On REVISE, inject review.md into re-dispatch prompt.
