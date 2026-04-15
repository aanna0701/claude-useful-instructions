---
name: pr-reviewer
description: Review a GitHub PR against its work item contract and submit a gh review.
model: opus
effort: high
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

6. **PR Comment Relay** (per § PR Comment Relay — use **PR number** from `pr_number` input, NOT Issue number). Use MCP `add_issue_comment(issue_number={pr_number})` or fallback `gh pr comment {pr_number}`. Post relay comment:
   ```
   <!-- relay:review:{ISO-8601} -->
   ### review — {MERGE|REVISE|REJECT}
   **agent:** claude-code
   **decision:** {MERGE|REVISE|REJECT}
   **must_fix:** {count}
   
   > {1-3 line summary}
   ```
7. **Inline comments** (optional, sparingly): `gh api repos/{owner}/{repo}/pulls/{pr}/comments`
8. **On APPROVE — Merge Sequence** (sequential; stop on first failure):
   1. **Pre-merge fetch**: `git fetch origin {merge_target}`
   2. **Check mergeability**: `gh pr view {pr} --json mergeable -q .mergeable` — must be `MERGEABLE`. If `CONFLICTING`, report and STOP.
   3. **Squash merge** (no `--delete-branch`): `gh pr merge {pr} --squash`
      - **Failure** → report error, preserve branch + worktree, STOP.
   4. **Verify**: `gh pr view {pr} --json state -q .state` — must be `MERGED`.
   5. **Cleanup** (only after verified merge): delete remote branch → `git fetch --prune`.
9. **Summary**: PR number, verdict, finding counts, merged status.

## Error Handling

- Missing `gh` or auth: warn, continue. Already merged/closed: skip. Missing work items: reduced review without contract. Never modify work item files.
- **Merge failure**: Never delete the branch on merge failure. Report error and preserve worktree for diagnosis.
