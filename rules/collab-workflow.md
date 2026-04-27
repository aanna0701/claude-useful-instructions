# Local Work-Item Workflow (v3, no-PR)

State of every work item is derived from `.work/contracts/` + `git worktree list` + branch ancestry. **No GitHub PRs, no Actions, no `gh` calls.**

The contract directory acts as the "PR" — it is created on `/work-plan` and deleted on `/work-review` APPROVE. Reviews are local markdown files inside the contract directory.

## Roles

- **Claude Code (session AI)**: drives `/work-plan`, `/work-impl`, `/work-refactor`, `/work-review`, `/work-status`. There is no other executor.

## Pipeline

```
plan ──▶ impl | refactor ──▶ review ──▶ (APPROVE → squash-merge + rm contract)
                                  │
                                  └──── CHANGES_REQUESTED → re-run impl/refactor
```

- `impl` handles FEAT / FIX / PERF / CHORE / TEST.
- `refactor` handles REFAC.
- On `CHANGES_REQUESTED`, re-run the same `/work-impl` or `/work-refactor`.

## Commands

| Command | Subject |
|---|---|
| `/work-plan` | Create item (contract + branch + worktree, optional push, **no PR**) |
| `/work-impl {ID}` | Implement (FEAT/FIX/PERF/CHORE/TEST) |
| `/work-refactor {ID}` | Refactor (REFAC) |
| `/work-review {ID}` | Write review file; on APPROVE squash-merge locally + delete contract |
| `/work-status [ID]` | Read-only view from `.work/contracts/` + `git` |

## Per-item files (authoritative, local-only)

```
.work/contracts/{ID}-{slug}/
  contract.md            # human-authored spec (created by /work-plan)
  .ready                 # sentinel touched by /work-impl|/work-refactor when ready for review
  review-{shortSHA}.md   # one per review pass (written by /work-review)
```

- `.work/` is **gitignored**. Contracts never reach the remote.
- `/work-plan` materializes `contract.md` into both the main repo and the worktree.
- `/work-review` writes `review-*.md` into both locations.
- `/work-review` APPROVE = `rm -rf .work/contracts/{ID}-{slug}/` (= "PR close").

## State derivation

| Signal in contract dir                                       | Status            |
|--------------------------------------------------------------|-------------------|
| no commits beyond parent                                     | `planned`         |
| commits exist, no `.ready` and no `review-*.md`              | `in-progress`    |
| `.ready` exists, no `review-*.md` for current SHA            | `awaiting-review` |
| latest `review-*.md` says `CHANGES_REQUESTED`                | `revising`        |
| latest `review-*.md` says `APPROVED`, branch not yet merged  | `ready-to-merge`  |
| branch ancestor of parent (merged), contract dir gone        | `done` (hidden)   |

`git` failure → raise error. No fallback.

## Branch convention

- `feature-{TYPE}-{slug}` — `TYPE ∈ {feat, fix, perf, chore, test, refac}`, `slug` kebab-case ≤ 40 chars.
- Enforced by `hooks/branch-naming`.

## Worktree convention

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
PROJECT="$(basename "$REPO_ROOT")"
WT_PATH="$(dirname "$REPO_ROOT")/${PROJECT}-${BRANCH}"
```

All output paths absolute. `/work-plan` creates branch + worktree. `hooks/worktree-cleanup` removes them after a local `git merge` (and also wipes the contract directory if it survived).

## Review

A review file is plain markdown inside the contract directory:

```markdown
# Review {ID} @ {shortSHA}

**Status**: APPROVED | CHANGES_REQUESTED
**Reviewer**: claude-code
**Reviewed at**: <ISO timestamp>

## Summary
<one paragraph>

## MUST-fix
- [ ] `path/to/file.py:42` — <comment>

## SHOULD
- <comment>

## NICE
- <comment>
```

- **MUST-fix** items block merge.
- **SHOULD / NICE** are advisory.
- On re-entry, `/work-impl` and `/work-refactor` read the latest `review-*.md` as their punch list.

## Merge

- Squash merge into the parent branch performed locally by `/work-review` on APPROVE.
- Optional `git push` after merge (only if `origin` exists).
- `worktree-cleanup` hook fires on the `git merge` and removes the worktree, local branch, and remote branch (if any).
- Contract directory deletion is part of the merge step itself.

## Verification

| Layer | When | Scope | On fail |
|---|---|---|---|
| pre-commit | before local commit | staged files | block commit |
| `/work-review` rerun of pre-commit on diff range | before APPROVE | parent..HEAD | block APPROVE |

There is no CI. The user explicitly opted out of GitHub Actions to control cost.

## Hooks

| Hook | Role |
|---|---|
| `branch-naming` | Enforce `feature-{TYPE}-{slug}` |
| `guard-branch` | Block code edits on main; create worktree (no PR) |
| `worktree-cleanup` | After `git merge`: remove worktree, local + remote branch, contract dir |

## CHANGES_REQUESTED re-entry

1. Run `/work-impl {ID}` or `/work-refactor {ID}` again.
2. Claude reads:
   - `contract.md`
   - the latest `review-*.md` (treat MUST-fix as the punch list)
   - `git diff $PARENT...HEAD`
3. Apply fixes → commit → touch `.ready`.
4. Re-run `/work-review`.

## Principles

- `.work/contracts/` + `git` = single source of truth. No GitHub state.
- Contract is the only human-authored spec per item.
- Reviews are local files; APPROVE = squash-merge + delete contract dir.
- `git` failures raise errors; no degraded modes.
