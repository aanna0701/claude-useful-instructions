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
   - Else if all good:
     ```bash
     gh pr review $PR_NUMBER --approve --body "$summary"
     ```
6. **Output** — review URL + decision + count of MUST-fix / SHOULD.

## After review

- `CHANGES_REQUESTED` → user runs `/work-impl {ID}` or `/work-refactor {ID}` again (re-entry reads unresolved threads automatically).
- `APPROVED` + CI green → user runs `gh pr merge {N} --squash --delete-branch`.

## Errors

- `gh` failure → raise, no fallback.
- PR not found → `ERROR: no open PR on head feature-*-${slug}`.
- CI still running → warn but allow review (user decision).
