---
name: collab-workflow
description: >
  Claude-Codex collaboration workflow for structured design-implement-review cycles.
  Triggers on: "work item", "work plan", "work review", "work status", "codex",
  "hand off", "delegate", "FEAT-", "multi-agent", "parallel", "dispatch", "boundary check",
  "worktree", "link work", "concurrent", "branch map", "branch init", "branch status",
  "merge target", "trunk chain", "working parent", "CI audit", "gha sync", "workflow audit".
---

# Claude-Codex Collaboration Workflow

## Routing

| User Intent | Route To |
|-------------|----------|
| Plan work item(s) | `/work-plan` |
| Check status | `/work-status` |
| Review + merge | `/work-review` |
| Set up branch hierarchy | `/branch-init` |
| Show branch state / freshness | `/branch-status` |
| Audit / fix / generate CI workflows | `/gha-branch-sync` |
| Boundary check / dispatch | `codex-run.sh` (suggest command) |
| Link worktrees | `link-work.sh` (suggest command) |

## References

- Rule: `.claude/rules/collab-workflow.md`
- Rule: `.claude/rules/branch-map-policy.md`
- Rule: `.claude/rules/review-merge-policy.md`
- Config: `.claude/branch-map.yaml` (project branch hierarchy)
- Docs: `docs/collab-workflow.md` (full setup guide + walkthrough)
- Scripts: `codex-run.sh`, `link-work.sh`
- Templates: `.claude/templates/work-item/`, `.claude/templates/branch-map/`
