# work-impl — Implement a Work Item (Cursor)

For `FEAT / FIX / PERF / CHORE / TEST`.

**You are Cursor Composer/Agent running in the work item's worktree.**
Claude Code already ran `/work-plan` → contract + branch + worktree + draft PR exist.
Your job: read the contract + PR, implement across files, commit + push.

> Prerequisite: Cursor must be opened on the **worktree directory**
> (`{PROJECT}-feature-{type}-{slug}`), not the repo root. If you are at the repo
> root, STOP and ask the user to reopen the worktree.

## Input

```
/work-impl {ID}        # e.g. /work-impl FEAT-042
```

## Steps

1. **Verify worktree context**:
   ```bash
   REPO_ROOT="$(git rev-parse --show-toplevel)"
   BRANCH="$(git rev-parse --abbrev-ref HEAD)"
   ```
   - `BRANCH` must match `feature-*` pattern. If on `main` → `ERROR: run /work-plan first or open the worktree`.
   - `REPO_ROOT` should end with the branch slug (worktree convention). If not, warn but continue.

2. **Read contract**:
   - `work/items/{ID}-*/contract.md` (glob — slug is unknown until lookup)
   - Parse `Boundaries.Touch` / `Boundaries.Forbidden` / `Acceptance`.

3. **Check re-entry** — PR `reviewDecision`:
   ```bash
   PR_NUMBER=$(gh pr list --head "$BRANCH" --json number --jq '.[0].number')
   DECISION=$(gh pr view "$PR_NUMBER" --json reviewDecision --jq '.reviewDecision')
   ```
   If `DECISION = CHANGES_REQUESTED`, fetch **unresolved review threads**:
   ```bash
   OWNER=$(gh repo view --json owner --jq '.owner.login')
   REPO=$(gh repo view --json name --jq '.name')
   gh api graphql -f query='
     query($o:String!,$r:String!,$n:Int!){
       repository(owner:$o,name:$r){
         pullRequest(number:$n){
           reviewThreads(first:100){
             nodes{ id isResolved path line comments(first:5){nodes{body}} }
     }}}}' -f o=$OWNER -f r=$REPO -F n=$PR_NUMBER \
     | jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved==false)'
   ```
   These threads = MUST-fix list. Remember each `id` for step 6.

4. **Implement** — use Composer/Agent for multi-file edits:
   - Honor `contract.Boundaries.Touch` globs; never modify `Forbidden`.
   - On re-entry, resolve every unresolved thread from step 3.
   - Prefer small coherent commits over one giant commit.
   - Keep tests green between commits.

5. **Commit + push** (`-s` required for DCO):
   ```bash
   git add -A
   git commit -s -m "{type}({ID}): <one-line description>"
   git push
   ```
   - Pre-commit hook runs ruff / mypy / pyright / clang-format — if it fails, fix and retry (do NOT use `--no-verify`).
   - On push, `auto-pr-commit` hook maintains PR body; CI (`pr-checks.yml`) runs remotely.

6. **Resolve review threads** — for each thread fixed in step 4:
   ```bash
   gh api graphql -f query='mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{id}}}' -f id=$THREAD_ID
   ```

7. **Promote draft → ready** if acceptance met and first pass:
   ```bash
   gh pr ready "$PR_NUMBER"
   ```

8. **Summary** — print:
   ```bash
   gh pr view "$PR_NUMBER" --json state,reviewDecision,statusCheckRollup,url
   ```

## Output

- PR URL
- CI check status (SUCCESS / FAILURE / PENDING)
- `reviewDecision`
- Next step hint: `/work-review {ID}` (run from Claude Code)

## Errors

- `gh` or `git` failure → raise, no fallback.
- Worktree not found / on main branch → direct user to `/work-plan`.
- Contract touches outside `Touch` globs → stop, report violation, do not push.
- Pre-commit hook failure → fix issue, re-stage, create NEW commit (never `--amend` or `--no-verify`).
