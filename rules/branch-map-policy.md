# Branch Map Policy

## Canonical Schema

All collaboration tooling must treat `.claude/branch-map.yaml` as a small, stable schema.

Required top-level fields:
- `version`
- `trunk_chain`
- `working_parent`
- `default_merge_target`
- `branch_prefixes`
- `merge_policy`

Optional top-level fields:
- `roles`
- `branches`

Rules:
- `working_parent` must be the last entry in `trunk_chain`
- `default_merge_target` is the merge target for normal FEAT/FIX/DOCS branches and should usually equal `working_parent`
- `branch_prefixes.<type>` defines branch naming for `/work-plan`
- `roles.<role>.paths` defines file ownership for routing and review validation
- `branches.<name>` is reserved for integration branches or exceptional overrides, not for every feature branch

## Branch Selection

1. Read `.claude/branch-map.yaml` before creating, syncing, reviewing, or merging branches.
2. If the file is missing, initialize it once via `/branch-init`.
3. Never hardcode merge targets in commands or prompts.
4. Feature branches are created from `working_parent`.
5. Feature branches merge into `default_merge_target` unless the contract declares an explicit override.

## Safety Rules

- Never implement directly on `working_parent`.
- Never use the orchestrator branch as an implementation workspace.
- Never sync sibling feature branches directly. Sync only from the feature branch's declared parent.
- Never merge if the branch is behind its parent.
- Never assume `main`, `develop`, or `research` exists. Use `trunk_chain`.
- A feature branch may only merge or rebase from its declared parent branch.

## Ownership Rules

- `working_parent` is the orchestration branch. It holds plans, manifests, and merge integration.
- Feature branches hold implementation changes and authoritative work-item status while work is active.
- `roles.*.paths` should be specific enough for review-time changed-file validation.

## Hub-and-Spoke Auto-Sync

Feature branches sync through the hub (`working_parent`), never directly between siblings:

```
feature-A -> working_parent -> feature-B
feature-B -> working_parent -> feature-A
```

Auto-sync is useful for branch freshness, but it does not replace work-item dependency checks.

## CI and Merge Gating

When branch-map changes:
- Re-audit any workflow that assumes fixed branch names
- Re-check merge automation defaults
- Re-check feature prefix detection in tooling

Minimum merge expectations:
- parent freshness gate
- merge target from contract or branch-map
- optional CI gate from `merge_policy.require_green_ci`

## Examples

```
main -> feat/*                        working_parent: main
main -> develop -> feat/*             working_parent: develop
main -> develop -> research -> feat/* working_parent: research
```
