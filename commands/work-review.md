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
6. **Output** — review URL + decision + count of MUST-fix / SHOULD + (on approve) gate label `reviewed:passed:{short_sha}`.

## After review

- `CHANGES_REQUESTED` → user runs `/work-impl {ID}` or `/work-refactor {ID}` again. A new push changes HEAD sha, which invalidates the previous `reviewed:passed:*` label — `/work-review` must re-run before merge.
- `APPROVED` + CI green + `reviewed:passed:{HEAD_short}` label → user runs `gh pr merge {N} --squash --delete-branch`. The `guard-merge` hook checks for this label/sha match and blocks the merge otherwise (covering `gh pr merge`, `gh api .../pulls/N/merge`, and MCP merge tools).

## Errors

- `gh` failure → raise, no fallback.
- PR not found → `ERROR: no open PR on head feature-*-${slug}`.
- CI still running → warn but allow review (user decision).
