# work-review — Review a PR

Read the PR diff + contract, submit a GitHub review with inline MUST-fix comments.

## Input

```
/work-review {ID}      # e.g. /work-review FEAT-042
```

## Steps

1. **Resolve PR** by branch:
   ```bash
   PR=$(gh pr list --head "feature-*-${slug}" --json number,url,headRefName,baseRefName --jq '.[0]')
   ```
2. **Read inputs**:
   - `contract.md` in the worktree (resolve worktree via `git worktree list`)
   - PR diff: `gh pr diff $PR_NUMBER`
   - CI status: `gh pr checks $PR_NUMBER`
3. **Evaluate** against contract:
   - Boundaries respected (Touch / Forbidden / Preserve)?
   - Acceptance criteria satisfied?
   - CI green?
   - Code quality (readability, error handling, tests coverage of acceptance)?
4. **Classify findings**:
   - **MUST-fix** → inline comments at `path:line` via GraphQL `addPullRequestReviewThread`:
     ```bash
     gh api graphql -f query='
       mutation($prId:ID!,$body:String!,$path:String!,$line:Int!,$side:DiffSide!){
         addPullRequestReviewThread(input:{
           pullRequestId:$prId, body:$body, path:$path, line:$line, side:$side
         }){ thread{ id } }
       }' -f prId=$PR_NODE_ID -f body="$comment" -f path="$file" -F line=$line -f side=RIGHT
     ```
   - **SHOULD / NICE** → top-level review body.
5. **Submit review**:
   - If MUST-fix present:
     ```bash
     gh pr review $PR_NUMBER --request-changes --body "$summary"
     ```
     Also remove any stale review label (so guard-merge keeps blocking):
     ```bash
     for lbl in $(gh pr view $PR_NUMBER --json labels --jq '.labels[].name' | grep '^reviewed:passed:'); do
       gh pr edit $PR_NUMBER --remove-label "$lbl"
     done
     ```
   - Else if all good — approve **and mint the merge gate label**:
     ```bash
     gh pr review $PR_NUMBER --approve --body "$summary" || true  # self-approve may fail; that's ok
     HEAD_SHA=$(gh pr view $PR_NUMBER --json headRefOid --jq .headRefOid)
     SHORT=${HEAD_SHA:0:7}
     # clear stale review labels for older shas
     for lbl in $(gh pr view $PR_NUMBER --json labels --jq '.labels[].name' | grep '^reviewed:passed:' | grep -v "reviewed:passed:$SHORT"); do
       gh pr edit $PR_NUMBER --remove-label "$lbl"
     done
     # ensure label exists in repo (idempotent), then apply
     gh label create "reviewed:passed:$SHORT" --color "0E8A16" --description "work-review passed at $SHORT" 2>/dev/null || true
     gh pr edit $PR_NUMBER --add-label "reviewed:passed:$SHORT"
     ```
6. **Auto-merge (on APPROVE only)** — per `rules/review-merge-policy.md`. Skip and report reason if any precondition fails:
   1. Acquire lock: `source lib/merge-lock.sh && acquire_merge_lock || { echo "skip: merge lock busy"; exit 0; }`
   2. Refetch state (CI + mergeability can flip during review):
      ```bash
      gh pr view $PR_NUMBER --json mergeable,mergeStateStatus,headRefName,baseRefName,reviewDecision \
        -q '{mergeable, mergeStateStatus, head: .headRefName, base: .baseRefName, decision: .reviewDecision}'
      ```
   3. Preconditions (all must hold — else `release_merge_lock` and skip with reason):
      - `mergeable == "MERGEABLE"`
      - `mergeStateStatus ∈ {CLEAN, HAS_HOOKS, UNSTABLE}` (UNSTABLE allowed only if non-required checks are the ones not green — otherwise block)
      - CI rollup green: `gh pr checks $PR_NUMBER` — all required checks `pass`
      - Parent fresh: `git fetch origin $BASE && git merge-base --is-ancestor origin/$BASE $HEAD_SHA`
      - Unresolved threads = 0:
        ```bash
        gh api graphql -f query='query($n:Int!,$o:String!,$r:String!){repository(owner:$o,name:$r){pullRequest(number:$n){reviewThreads(first:100){nodes{isResolved}}}}}' \
          -F n=$PR_NUMBER -f o=$OWNER -f r=$REPO \
          --jq '[.data.repository.pullRequest.reviewThreads.nodes[]|select(.isResolved==false)]|length'
        ```
   4. Merge (squash, **without** `--delete-branch` — deletion is a separate, verified step):
      ```bash
      gh pr merge $PR_NUMBER --squash --subject "$(gh pr view $PR_NUMBER --json title --jq .title) (#$PR_NUMBER)"
      ```
   5. Verify: `gh pr view $PR_NUMBER --json state --jq .state` must be `MERGED`. If not, `release_merge_lock` and raise — **do not delete branch**.
   6. Delete remote branch only after verified merge:
      ```bash
      gh api --method DELETE "repos/$OWNER/$REPO/git/refs/heads/$HEAD_BRANCH" || \
        git push origin --delete "$HEAD_BRANCH"
      ```
   7. `release_merge_lock`.
   8. `git pull` on the main worktree is handled automatically by the `git-auto-pull` PostToolUse hook (`hooks/git-auto-pull/post_merge_pull.py`). Worktree cleanup is handled by the `worktree-cleanup` hook. No manual step required.
7. **Output** — review URL + decision + count of MUST-fix / SHOULD + (on approve) gate label `reviewed:passed:{short_sha}` + auto-merge result (`merged` | `skipped: <reason>`).

## After review

- `CHANGES_REQUESTED` → user runs `/work-impl {ID}` or `/work-refactor {ID}` again. A new push changes HEAD sha, which invalidates the previous `reviewed:passed:*` label — `/work-review` must re-run before merge.
- `APPROVED` + preconditions met → `/work-review` auto-merges (squash) and deletes the remote branch. The `git-auto-pull` hook fast-forwards the main worktree; `worktree-cleanup` removes the feature worktree. User takes no further action.
- `APPROVED` + auto-merge skipped (CI not green, threads unresolved, mergeable != `MERGEABLE`, parent stale, or lock busy) → `reviewed:passed:{HEAD_short}` is already applied. User resolves the skip reason, then runs `gh pr merge {N} --squash` manually. The `guard-merge` hook validates label/sha + CI before allowing the merge.

## Errors

- `gh` failure → raise, no fallback.
- PR not found → `ERROR: no open PR on head feature-*-${slug}`.
- CI still running → warn but allow review (user decision).
