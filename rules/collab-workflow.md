# Claude-Codex-Cursor Collaboration (v2)

State of every work item is derived from GitHub PR + git. No md file stores state.

## Roles

- **Claude Code (session AI)**: drives `/work-plan`, `/work-review`, `/work-status`. Can also run `/work-impl` and `/work-refactor` (tries Codex first, falls back in-session).
- **Cursor (interactive implementer)**: opens the worktree, runs `/work-impl {ID}` or `/work-refactor {ID}` from `.cursor/commands/`. Preferred for coordinated multi-file edits within a single work item (Composer's strength).
- **Codex (unattended)**: `bash codex-run.sh {ID}` — same contract, runs without supervision. Preferred for running many independent work items in parallel.

Each executor reads the same inputs (contract + unresolved review threads + diff) and produces the same outputs (commits + push + resolved threads).

## Pipeline

```
plan (Claude) ──▶ impl | refactor ──(push → CI)──▶ review (Claude) ──▶ merge
                     │                                    │
                     ├─ Cursor  (interactive)             │
                     ├─ Codex   (unattended)              │
                     └─ Claude  (session fallback)        │
                          ▲                               │
                          └──────── CHANGES_REQUESTED ────┘
```

- `impl` handles FEAT / FIX / PERF / CHORE / TEST.
- `refactor` handles REFAC.
- `revise` is not a stage — on `CHANGES_REQUESTED`, re-run the same `/work-impl` or `/work-refactor`.
- `verify` is not a stage — CI (`pr-checks.yml`) produces the check run.

## Commands

| Command | Subject |
|---|---|
| `/work-plan` | Create item (contract + branch + worktree + draft PR) |
| `/work-impl {ID}` | Implement (FEAT/FIX/PERF/CHORE/TEST) |
| `/work-refactor {ID}` | Refactor (REFAC) |
| `/work-review {ID}` | `gh pr review` with inline MUST-fix comments |
| `/work-status [ID]` | Read-only view derived from `gh` + `git` |

No flags. Session context decides which AI runs.

## Per-item files (authoritative, worktree-local)

```
$WT_PATH/work/items/{ID}-{slug}/contract.md
```

One file per work item. Nothing else.

## State derivation

Sources (md never consulted):

```bash
gh pr list --state all --limit 100 --search "head:feature-" \
  --json number,headRefName,isDraft,state,reviewDecision,statusCheckRollup,title,url,commits
git worktree list --porcelain
```

Join on `headRefName ↔ worktree branch`. Derive:

| Observable | Status |
|---|---|
| `pr.state = MERGED` | merged |
| `pr.state = CLOSED` (unmerged) | abandoned |
| `isDraft && checks = SUCCESS` | ready (promote needed) |
| `isDraft` | implementing |
| `!isDraft && reviewDecision = CHANGES_REQUESTED` | revising |
| `!isDraft && reviewDecision = APPROVED && checks = SUCCESS` | ready-to-merge |
| `!isDraft` | reviewing |

`gh` or `git` failure → raise error. No fallback.

## Branch convention

- `feature-{TYPE}-{slug}` — `TYPE ∈ {feat, fix, perf, chore, test, refac}`, `slug` kebab-case ≤ 40 chars.
- Enforced by `hooks/branch-naming`.

## Worktree convention

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
PROJECT="$(basename "$REPO_ROOT")"
WT_PATH="$(dirname "$REPO_ROOT")/${PROJECT}-${BRANCH}"
```

All output paths absolute. `/work-plan` creates branch + worktree. `hooks/worktree-cleanup` removes them after merge.

## PR body (machine-readable)

```
<!-- work-item:{ID} -->
<!-- work-type:{TYPE} -->

## Contract
See work/items/{ID}-{slug}/contract.md

## Acceptance
- [ ] ...
```

`hooks/auto-pr-commit` injects this on draft PR creation. Body below is user-editable.

## Review

- **MUST-fix → inline** (GraphQL `addPullRequestReviewThread` with path + line).
- **SHOULD / NICE → top-level body** (`gh pr review --body`).
- Decision via `gh pr review --approve` or `--request-changes`.
- After fix commits, each resolved thread: GraphQL `resolveReviewThread`.

## Merge

- Squash merge only. Rebase / merge-commit disabled at repo level.
- `gh pr merge {N} --squash --delete-branch` by the approver.
- No auto-merge.

## CI (required)

`templates/.github/workflows/pr-checks.yml` is bundled and installed by `install.sh`.

- Python: `ruff check . && mypy . && pytest`
- Triggers on `pull_request` (opened/synchronize/reopened/ready_for_review) and `push` to main.
- Produces check run `check` on the PR.

Branch protection (set by `install.sh`):
- Require PR, approvals ≥ 1
- Require check `check` passing, branch up-to-date
- Require conversation resolution
- No force push, no deletion on main

## Verification layers (intentional overlap)

| Layer | When | Scope | On fail |
|---|---|---|---|
| pre-commit | before local commit | staged files | block commit |
| CI on PR | after push to PR branch | changed .py files + related test dirs | block merge |
| CI on main push | after squash merge | whole repo | surface repo-wide regressions |

## Hooks

| Hook | Role |
|---|---|
| `branch-naming` | Enforce `feature-{TYPE}-{slug}` |
| `guard-branch` | Block edits on main; create worktree |
| `guard-merge` | Block direct merges into protected branches |
| `auto-pr-commit` | On first commit in worktree: push + create draft PR with standard body |
| `auto-pr` | Fallback draft PR creation on Stop |
| `worktree-cleanup` | Remove worktree + local branch after merge |
| `git-auto-pull` | Keep base branch current |

## CHANGES_REQUESTED re-entry

1. Run `/work-impl {ID}` or `/work-refactor {ID}` again (same command).
2. Session AI / codex-run.sh assembles prompt with:
   - `contract.md`
   - unresolved review threads (GraphQL `reviewThreads { isResolved path line comments }`)
   - `git diff origin/{base}...HEAD`
3. Apply fixes → commit → push.
4. Resolve each fixed thread via GraphQL `resolveReviewThread`.
5. `/work-review` re-runs to approve.

## Principles

- PR + git = single source of truth. md files never store state.
- Contract is the only human-authored spec per item.
- Session context chooses the AI; commands take no flags.
- `gh` / `git` failures raise errors; no degraded modes.
