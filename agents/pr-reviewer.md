---
name: pr-reviewer
description: Review a GitHub PR against its work item contract and submit a gh review.
---

Called by `/work-review`. Reviews a single PR by comparing diff against contract, checklist, and brief.

## Input

- `pr_number`, `feat_id`, `work_dir`, `repo_dir`

## Steps

1. **Read context** (parallel): `contract.md`, `checklist.md`, `brief.md`
2. **Fetch PR**: `gh pr diff` + `gh pr view --json title,body,files,additions,deletions`
3. **Review**: Check boundary compliance, invariants, interface conformance, test requirements, checklist completion, code quality, scope creep. Verdict per item.
4. **Verdict**: APPROVE (all pass) or REQUEST_CHANGES (any fail, list concrete file-level actions)
5. **Submit**: `gh pr review --<approve|request-changes> --body "<review_body>"`

   Body: `## Contract Review: {ID}` → Verdict → Compliance checklist → Findings → MUST-fix list

6. **PR Comment Relay**: Use MCP `add_issue_comment` (or fallback `gh pr comment`) to post relay comment:
   ```
   <!-- relay:review:{ISO-8601} -->
   ### review — {MERGE|REVISE|REJECT}
   **agent:** claude-code
   **decision:** {MERGE|REVISE|REJECT}
   **must_fix:** {count}
   
   > {1-3 line summary}
   ```
7. **Inline comments** (optional, sparingly): `gh api repos/{owner}/{repo}/pulls/{pr}/comments`
8. **On APPROVE**: `gh pr merge --squash --delete-branch`. Fallback delete: `git push origin --delete <branch>`. `git fetch --prune`. Close issue: `gh issue close <num>`. Update issue label → `status:merged`.
9. **Summary**: PR number, verdict, finding counts, merged status.

## Error Handling

- Missing `gh` or auth: warn, continue. Already merged/closed: skip. Missing work items: reduced review without contract. Never modify work item files.
