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

## Hub-and-Spoke Auto-Sync

Feature branches sync through the hub (working_parent), never directly between siblings:

```
feature-A ──push──→ hub (working_parent) ──cascade──→ feature-B
feature-B ──push──→ hub (working_parent) ──cascade──→ feature-A
```

### Auto-Sync (GitHub Actions)

- Workflow: `.github/workflows/branch-auto-sync.yml`
- Reads `.claude/branch-map.yaml` to determine hub and children
- Phase 1 (UP): merges trigger branch into `merge_target` (or `working_parent` fallback)
- Phase 2 (DOWN): cascades hub changes to all children
  - Explicit children from `branches:` section
  - Auto-detected feature branches from remote (`feature-*`, `feat/*`)
- Conflicts are skipped with a warning (manual resolution required)

### Auto-Pull (Claude Code Hook)

- Hook: `hooks/git-auto-pull/auto_pull.py`
- PreToolUse hook on `Edit|Write|NotebookEdit`
- Runs `git pull --ff-only` once per session before first file-modifying tool
- Skips if no remote tracking or not a git repo

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
