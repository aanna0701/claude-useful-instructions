---
name: collab-workflow
description: >
  Claude-Codex collaboration workflow for structured design-implement-review cycles.
  Triggers on: "work item", "FEAT-", "REFAC-", "AUDIT-", "collab-workflow",
  "/work-plan", "/work-scaffold", "/work-verify", "/work-review", "/work-status",
  "branch map", "branch init", "codex-run".
---

# Claude-Codex Collaboration Workflow

## Routing

| User Intent | Route To |
|-------------|----------|
| Full pipeline | `/collab-workflow {instruction}` |
| Plan | `/work-plan` |
| Scaffold | `/work-scaffold` (Cursor) or `--claude` |
| Implement | `codex-run.sh` or `/work-impl` (Claude) |
| Verify | `/work-verify` (Cursor) or `--claude` |
| Review + merge | `/work-review` |
| Status | `/work-status` |
| Re-dispatch | `/work-revise` |
| Branch hierarchy | `/branch-init` |
| Branch state | `/branch-status` |
| CI audit | `/gha-branch-sync` |

Tool roles, state machine, worktree rules: `rules/collab-workflow.md`

## References

- Rules: `collab-workflow.md`, `branch-map-policy.md`, `review-merge-policy.md`
- Config: `.claude/branch-map.yaml`
- Scripts: `codex-run.sh`, `lib/codex-run-*.sh`
- Templates: `.claude/templates/{work-item,branch-map,cursor}/`
- Agents: `cursor-prompt-builder`, `work-reviser`, `pr-reviewer`, `ci-audit-agent`
- Pipeline: `templates/collab-pipeline-body.md` → installed to `.cursor/rules/collab-pipeline.mdc` + `.agent/workflows/collab-pipeline.md`
