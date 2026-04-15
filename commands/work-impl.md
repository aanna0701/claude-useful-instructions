# work-impl — Implement a Work Item

For `FEAT / FIX / PERF / CHORE / TEST`.

**Default flow:** try **Codex first** (unattended via `codex-run.sh`), then fall back to the current session (Claude/Cursor) if Codex fails, stalls, or leaves the contract unmet. Set `WORK_IMPL_SKIP_CODEX=1` to skip the Codex pass and implement directly in-session.

## Input

```
/work-impl {ID}        # e.g. /work-impl FEAT-042
```

## Steps

0. **Codex-first pass** (skip if `WORK_IMPL_SKIP_CODEX=1` or `codex` CLI not installed):
   ```bash
   if [ -z "${WORK_IMPL_SKIP_CODEX:-}" ] && command -v codex >/dev/null 2>&1; then
     bash "$(git rev-parse --show-toplevel)/codex-run.sh" {ID} || CODEX_FAILED=1
   else
     CODEX_FAILED=1
   fi
   ```
   After the Codex pass, re-check PR state:
   - If PR is green (`statusCheckRollup` all SUCCESS) and acceptance is met → skip to step 7 (promote draft → ready) and 8 (summary).
   - If Codex stalled, pushed nothing, or left failing checks / unresolved threads → continue from step 1 to finish the work in-session.

1. **Resolve worktree** by branch convention:
   ```bash
   BRANCH=$(git branch --list "feature-*-${slug}" | head -1)   # or look up via PR headRefName
   WT_PATH=$(git worktree list --porcelain | awk -v b="$BRANCH" '$1=="worktree"{p=$2} $1=="branch" && $2=="refs/heads/"b{print p}')
   ```
   If unresolved → `ERROR: worktree for {ID} not found. Run /work-plan or check git worktree list.`
2. **Read inputs** from worktree:
   - `$WT_PATH/work/items/{ID}-{slug}/contract.md`
3. **Check re-entry** — PR `reviewDecision`:
   ```bash
   PR=$(gh pr list --head "$BRANCH" --json number,reviewDecision --jq '.[0]')
   ```
   If `reviewDecision = CHANGES_REQUESTED`, fetch **unresolved review threads**:
   ```bash
   gh api graphql -f query='
     query($o:String!,$r:String!,$n:Int!){
       repository(owner:$o,name:$r){
         pullRequest(number:$n){
           reviewThreads(first:100){
             nodes{ id isResolved path line comments(first:5){nodes{body}} }
     }}}}' -f o=$OWNER -f r=$REPO -F n=$PR_NUMBER \
     | jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved==false)'
   ```
   These threads = MUST-fix list.
4. **Implement** in `$WT_PATH`:
   - Honor `contract.Boundaries.Touch` / `Forbidden`.
   - On re-entry, resolve every unresolved thread.
   - Keep tests green between commits. Small commits.
5. **Commit + push** (`-s` required for DCO):
   ```bash
   cd "$WT_PATH"
   git add -A
   git commit -s -m "{type}({ID}): <description>"
   git push
   ```
   Pre-commit runs ruff + mypy + pyright + clang-format. CI (`pr-checks.yml`) runs on push.
6. **Resolve review threads** — for each fixed thread:
   ```bash
   gh api graphql -f query='mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{id}}}' -f id=$THREAD_ID
   ```
7. **Promote draft → ready** if acceptance met and checks green (first pass only):
   ```bash
   gh pr ready $PR_NUMBER
   ```
8. **Summary** — print `gh pr view --json state,reviewDecision,statusCheckRollup` result.

## Output

- PR URL
- CI check status (SUCCESS / FAILURE / PENDING)
- `reviewDecision`

## Errors

- `gh` or `git` failure → raise, no fallback.
- Worktree not found → direct to `/work-plan`.
- Contract touches outside `Touch` globs → stop, report violation.
