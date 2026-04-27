# work-status — View Work Items (Local-Only)

Read-only. State is derived from `.work/contracts/` + `git worktree list` + branch ancestry. **No GitHub calls.**

## Input

```
/work-status            # all active items
/work-status {ID}       # single item detail
```

## Steps

1. **Enumerate contracts**:
   ```bash
   ls -d .work/contracts/*/ 2>/dev/null   # each entry = {ID}-{slug}/
   ```
2. **Fetch worktrees**:
   ```bash
   git worktree list --porcelain
   ```
3. **Join** `{ID}-{slug}` ↔ `feature-{type}-{slug}` ↔ worktree path.
4. **Derive status** for each row (no PR concept — local signals only):

   | Signal in contract dir                                       | Status            |
   |--------------------------------------------------------------|-------------------|
   | no commits beyond parent                                     | `planned`         |
   | commits exist, no `.ready` and no `review-*.md`              | `in-progress`     |
   | `.ready` exists, no `review-*.md` for current SHA            | `awaiting-review` |
   | latest `review-*.md` says `CHANGES_REQUESTED`                | `revising`        |
   | latest `review-*.md` says `APPROVED`, branch not yet merged  | `ready-to-merge`  |
   | branch ancestor of parent (merged), contract dir gone        | `done` (hidden)   |

5. **Flag stale worktrees** — branch merged into parent but worktree still present → print cleanup hint (`worktree-cleanup` hook normally handles it on `git merge`; if absent, suggest `git worktree remove $WT_PATH`).

## Mode A: all items

Print a table sorted by latest commit time desc:

```
ID        Title                   Type  Status            Branch                         Worktree
FEAT-042  Add auth middleware     FEAT  ready-to-merge    feature-feat-auth-middleware   /abs/path
REFAC-007 Split db module         REFAC revising          feature-refac-split-db          /abs/path
```

## Mode B: single item

Print:
- Title, type, status
- Branch, worktree absolute path
- Last commit SHA + message
- Pre-commit result on the diff range (`pre-commit run --from-ref $PARENT --to-ref HEAD`)
- Latest review file path + decision + counts of MUST-fix / SHOULD
- Boundaries digest (Touch / Forbidden / Preserve globs from contract)

## Errors

- `git` failure → raise, no fallback.
- Contract directory missing for an existing `feature-*` branch → warn, suggest `/work-plan`.

## Notes

- Title is the H1 of `contract.md`.
- ID is the directory prefix `{TYPE}-{NNN}`.
- No filter on merged items; `done` is hidden because the contract directory is gone.
