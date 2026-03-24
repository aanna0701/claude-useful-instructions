---
name: collab-workflow
description: >
  Claude-Codex collaboration workflow for structured design-implement-review cycles.
  Triggers on: "work item", "work plan", "work review", "work status", "codex",
  "hand off", "delegate", "FEAT-", "multi-agent", "parallel", "dispatch", "boundary check",
  "worktree", "link work", "concurrent".
---

# Claude-Codex Collaboration Workflow

## Routing

| User Intent | Route To |
|-------------|----------|
| Plan work item(s) | `/work-plan` |
| Check status | `/work-status` |
| Review + merge | `/work-review` |
| Boundary check / dispatch | `codex-run.sh` (suggest command) |
| Link worktrees | `link-work.sh` (suggest command) |

## References

- Rule: `.claude/rules/collab-workflow.md`
- Docs: `docs/collab-workflow.md` (full setup guide + walkthrough)
- Scripts: `codex-run.sh`, `link-work.sh`
- Templates: `.claude/templates/work-item/`
