# Branch Map Policy

Source: `.claude/branch-map.yaml`

## Required Fields

`version`, `trunk_chain`, `working_parent`, `default_merge_target`, `branch_prefixes`, `merge_policy`

Rules:
- `working_parent` = last entry in `trunk_chain`
- `default_merge_target` = merge target for normal FEAT/FIX/DOCS branches (usually = `working_parent`)
- `branches.<name>` reserved for integration branches or exceptional overrides

## Safety Rules

- Never implement directly on `working_parent`.
- Never use the orchestrator branch as an implementation workspace.
- Never sync sibling feature branches directly — sync only from declared parent.
- Never merge if behind parent.
- Never hardcode branch names — read from `trunk_chain`.
- Feature branches created from and merge into `working_parent` (unless contract overrides).

## Ownership

- `working_parent` holds plans, manifests, and merge integration.
- Feature branches hold implementation and authoritative work-item status.
- `roles.*.paths` scopes file ownership for review validation.
