# Local Work-Item Workflow (v3, no-PR)

> **Doc type**: Explanation + Tutorial | **Audience**: Developers using Claude Code locally

The `workflow` bundle gives Claude Code a structured, **fully local** way to handle work items. v3 drops GitHub PRs and Actions entirely — the contract is a local directory under `.work/contracts/`, and "closing the PR" means `rm -rf` on that directory.

This change is intentional: avoid GitHub Actions cost. Branches still go on the remote (free) when `origin` exists, but no PR is opened and no CI runs.

---

## Roles

| Agent (Command) | Role |
|-----------------|------|
| **Claude** (all `/work-*` commands) | spec owner, implementer, reviewer, merger |

Per work item, the contract directory holds everything:

```
.work/contracts/{ID}-{slug}/
  contract.md            # human-authored spec
  .ready                 # touched when ready for review
  review-{shortSHA}.md   # one per review pass
```

`.work/` is gitignored. Contracts never reach the remote.

## Pipeline (4 stages)

```
/work-plan → /work-impl | /work-refactor → /work-review → (APPROVE → squash-merge + rm contract)
```

```
[Claude] /work-plan "Add JWT middleware"
  → creates .work/contracts/FEAT-042-jwt-middleware/contract.md,
    branch feature-feat-jwt-middleware, worktree at ../{project}-feature-feat-jwt-middleware
[Claude] /work-impl FEAT-042
  → commits in worktree, touches .ready
[Claude] /work-review FEAT-042
  → writes review-{sha}.md
  → on APPROVE: squash-merge into parent, deletes contract dir,
    worktree-cleanup hook removes worktree + branch
[Claude] /work-status
  → derives state from .work/contracts/ + git worktree list + branch ancestry
```

## State derivation

State is read from local signals only — no `gh` calls.

| Signal in contract dir                                       | Status            |
|--------------------------------------------------------------|-------------------|
| no commits beyond parent                                     | `planned`         |
| commits exist, no `.ready` and no `review-*.md`              | `in-progress`    |
| `.ready` exists, no `review-*.md` for current SHA            | `awaiting-review` |
| latest `review-*.md` says `CHANGES_REQUESTED`                | `revising`        |
| latest `review-*.md` says `APPROVED`, branch not yet merged  | `ready-to-merge`  |
| branch merged into parent, contract dir gone                 | `done` (hidden)   |

## Branch + worktree convention

- Branch: `feature-{TYPE}-{slug}` — `TYPE ∈ {feat, fix, perf, chore, test, refac}`.
- Worktree: `$(dirname $REPO_ROOT)/${PROJECT}-${BRANCH}` (sibling of repo).
- Enforced by the `branch-naming` and `guard-branch` hooks.

## Hooks

| Hook | Role |
|---|---|
| `branch-naming` | Enforce `feature-{TYPE}-{slug}` |
| `guard-branch` | Block code edits on the main worktree; auto-create a feature worktree (no PR) |
| `worktree-cleanup` | After local `git merge`: remove worktree, local branch, remote branch (if any), contract dir |

## Verification

| Layer | When | On fail |
|---|---|---|
| `pre-commit` | before local commit | block commit |
| `/work-review` rerun of pre-commit on diff range | before APPROVE | block APPROVE |

There is no CI. Pre-commit is the only automated gate.

## CHANGES_REQUESTED re-entry

1. Re-run `/work-impl {ID}` or `/work-refactor {ID}`.
2. Claude reads `contract.md` + the latest `review-*.md` + `git diff $PARENT...HEAD` and resolves every MUST-fix item.
3. New commits land on the same branch; touch `.ready` again.
4. Re-run `/work-review`.

## Why this changed

- v1 stored state in many md files → drift.
- v2 stored state on the GitHub PR + git → required Actions and `gh` for every operation.
- v3 stores state in a local `.work/contracts/` dir + git → fully offline-friendly, zero recurring cost, and "closing a PR" is just `rm -rf`.
