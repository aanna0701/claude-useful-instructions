---
name: collab-workflow
description: >
  Local-only work-item workflow for structured plan-implement-review cycles.
  No GitHub PRs, no Actions — contracts live in .work/contracts/.
  Triggers on: "work item", "FEAT-", "FIX-", "REFAC-", "collab-workflow",
  "/work-plan", "/work-impl", "/work-refactor", "/work-review", "/work-status".
---

# Local Work-Item Workflow (v3, no-PR)

State is derived from `.work/contracts/` + `git worktree list` + branch ancestry. **No GitHub state** — `gh` is never called by these commands.

The contract directory at `.work/contracts/{ID}-{slug}/` is the work item. Creating it is "open PR"; deleting it (on `/work-review` APPROVE) is "close PR".

## Routing

| User Intent | Route To |
|-------------|----------|
| Plan a work item | `/work-plan` |
| Implement (FEAT / FIX / PERF / CHORE / TEST) | `/work-impl` |
| Refactor (REFAC only) | `/work-refactor` |
| Review + (on APPROVE) local merge | `/work-review` |
| Status | `/work-status` |

Re-entry (`CHANGES_REQUESTED`) is handled inline: `/work-impl` and `/work-refactor` read the latest `review-*.md` and treat each MUST-fix item as the punch list.

## References

- Rules: `collab-workflow.md`, `review-merge-policy.md`
- Template: `templates/work-item/contract.md`
