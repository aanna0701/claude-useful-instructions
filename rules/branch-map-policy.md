# Branch Map Policy

## Branch Selection

1. Read `.claude/branch-map.yaml` before creating or merging branches.
2. If the file is missing, ask once: "Which branch do feature branches merge into?"
3. Persist the answer via `/branch-init`.
4. Derive merge targets from `trunk_chain` — never hardcode branch names.
5. Feature branches are based on `working_parent`, not on `main` unless `main` IS the working parent.

## Safety Rules

- Never sync sibling feature branches directly — always go through the parent.
- Never merge if the branch is behind its parent (rebase or merge from parent first).
- Never assume `main`, `develop`, or `research` exists — check `trunk_chain`.
- A feature branch may only rebase/merge FROM its parent branch.

## Worktree Routing (when collab workflow is active)

- Resolve implementation location from contract "Allowed Modifications" paths first.
- Fall back to `roles[].paths` in `branch-map.yaml` for worktree selection.
- If paths conflict between planning docs and contract, contract wins.
- Cross-cutting tasks that span multiple roles: split into separate work items or mark sequential.

## CI Auto-Sync

When `.claude/branch-map.yaml` is modified (trunk_chain, working_parent, or merge_policy changes):
- If `.github/workflows/` exists, proactively run `/gha-branch-sync` to detect misalignment.
- If a work item contract has a `CI Scope` field, verify that matching workflows exist for those checks.

## Examples

```
main -> feat/*                        working_parent: main
main -> develop -> feat/*             working_parent: develop
main -> develop -> research -> feat/* working_parent: research
```
