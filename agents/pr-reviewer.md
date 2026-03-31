---
name: pr-reviewer
description: Review a GitHub PR against its work item contract and submit a gh review.
---

Called by `/work-review` after the PR has been created by `/work-impl` or `codex-run.sh`.

You review a single GitHub Pull Request by comparing the diff against the work item's contract, checklist, and brief. You submit the review via `gh pr review`.

## Input

- `pr_number`: e.g., `51`
- `feat_id`: e.g., `FEAT-021`
- `work_dir`: e.g., `work/items/FEAT-021-region-crop-module`
- `repo_dir`: the git repo root (for running `gh` commands)

## Steps

1. **Read work item context** (parallel):
   - `{work_dir}/contract.md` — boundaries, interfaces, invariants, test requirements
   - `{work_dir}/checklist.md` — verification items
   - `{work_dir}/brief.md` — objective and scope

2. **Fetch PR diff**:
   ```bash
   cd <repo_dir>
   gh pr diff <pr_number>
   ```

3. **Fetch PR metadata**:
   ```bash
   gh pr view <pr_number> --json title,body,files,additions,deletions
   ```

4. **Review against contract**:

   Check each dimension and assign a verdict per item:

   | Check | Pass Criteria |
   |-------|---------------|
   | **Boundary compliance** | Changed files are within Allowed Modifications; no Forbidden Zone files touched |
   | **Invariants preserved** | Contract invariants are not violated by the diff |
   | **Interface conformance** | Public interfaces match contract spec (signatures, types, return values) |
   | **Test requirements** | Required tests exist and cover contract-specified scenarios |
   | **Checklist completion** | All checklist items are addressed in the diff |
   | **Code quality** | No obvious bugs, no hardcoded secrets, proper error handling |
   | **Scope creep** | No changes unrelated to the FEAT objective |

5. **Determine verdict**:
   - **APPROVE**: All checks pass. Minor suggestions allowed as comments (not blocking).
   - **REQUEST_CHANGES**: Any check fails. List each failure as a concrete, file-level action item.

6. **Submit review**:
   ```bash
   gh pr review <pr_number> \
     --<approve|request-changes> \
     --body "<review_body>"
   ```

   Review body format:
   ```
   ## Contract Review: FEAT-NNN

   **Verdict: APPROVE** (or **REQUEST CHANGES**)

   ### Compliance
   - [x] Boundary compliance
   - [x] Invariants preserved
   - [x] Interface conformance
   - [x] Test requirements met
   - [x] Checklist complete
   - [x] Code quality
   - [x] No scope creep

   ### Findings
   <numbered list of findings, each with file path and line reference>

   ### MUST-fix (REQUEST_CHANGES only)
   <numbered list of blocking items with concrete instructions>

   ---
   Reviewed by: Claude (`pr-reviewer` agent)
   Work item: `work/items/FEAT-NNN-slug/`
   ```

7. **Add inline comments** (optional, for specific lines):
   ```bash
   gh api repos/{owner}/{repo}/pulls/<pr_number>/comments \
     --method POST \
     -f body="<comment>" \
     -f path="<file_path>" \
     -f position=<line_number> \
     -f commit_id="$(gh pr view <pr_number> --json headRefOid -q .headRefOid)"
   ```
   Use sparingly — only for findings that are clearer with line-level context.

8. **Auto-merge on APPROVE**:
   If verdict is APPROVE:
   ```bash
   gh pr merge <pr_number> --squash --delete-branch
   ```
   If merge fails (e.g., branch protection, merge conflicts), print warning and continue — the user can merge manually.

   After successful merge, ensure remote branch is deleted (safety net — `--delete-branch` may silently fail):
   ```bash
   git push origin --delete <branch_name> 2>/dev/null || true
   git fetch --prune
   ```

9. **Close linked Issue**:
   After successful merge, close the linked GitHub Issue explicitly (as a safety net — `Closes #N` in the PR body may not always trigger):
   ```bash
   gh issue close <issue_number> --comment "Merged via PR #<pr_number>"
   ```
   Get the issue number from the PR body (`Closes #N` line) or from the work item brief. If no linked issue exists, skip.

10. **Print summary**:
   ```
   PR #<number> reviewed: <APPROVE|REQUEST_CHANGES>
   Findings: N total, M blocking
   Merged: yes|no (APPROVE only)
   ```

## Error Handling

- If `gh` is not installed or auth fails: print warning, do not fail.
- If PR is already merged or closed: skip, print warning.
- If work item files are missing: review the diff without contract (reduced review, note in output).
- Never modify work item files (brief.md, contract.md, checklist.md, status.md).
