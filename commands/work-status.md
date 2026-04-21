# work-status — View Work Items (PR-derived)

Read-only. State derived from `gh pr list` + `git worktree list`. No md files consulted.

## Input

```
/work-status            # all active items
/work-status {ID}       # single item detail
```

## Steps

1. **Fetch PRs**:
   ```bash
   gh pr list --state all --limit 100 --search "head:feature-" \
     --json number,headRefName,isDraft,state,reviewDecision,\
mergedAt,statusCheckRollup,updatedAt,title,url,commits,author
   ```
2. **Fetch worktrees**:
   ```bash
   git worktree list --porcelain
   ```
3. **Join** on `headRefName ↔ worktree branch`.
4. **Derive status** for each row — observable → status mapping per `rules/collab-workflow.md` §State derivation (authoritative SSOT).
5. **Flag stale worktrees** — merged PR but worktree still present → print cleanup hint.

## Mode A: all items

Print a table sorted by `updatedAt` desc:

```
ID        Title                      Type  Status          Branch                        PR    Worktree
FEAT-042  Add auth middleware        FEAT  ready-to-merge  feature-feat-auth-middleware  #128  /abs/path
REFAC-007 Split db module            REFAC revising        feature-refac-split-db         #131  /abs/path
```

## Mode B: single item

Print:
- Title, type, status
- Branch, PR URL, worktree absolute path
- CI checks breakdown (`gh pr checks {N}`)
- `reviewDecision`
- Unresolved review threads count (GraphQL)
- Last commit SHA + message

## Errors

- `gh` or `git` failure → raise, no fallback.
- `gh auth status` fail → `ERROR: run 'gh auth login'`.

## Notes

- No filter on merged/closed; the full list is shown. Use `gh pr list` directly for richer queries.
- ID parsing: extract from PR title prefix (`FEAT-042 ...`) or `headRefName`.
