---
name: collab-workflow
description: >
  PR-native Claude-Codex collaboration workflow for structured plan-implement-review cycles.
  Triggers on: "work item", "FEAT-", "FIX-", "REFAC-", "collab-workflow",
  "/work-plan", "/work-impl", "/work-refactor", "/work-review", "/work-status",
  "branch map", "branch init", "codex-run".
---

# Claude-Codex Collaboration Workflow (v2)

State is derived from the GitHub PR + git. No per-item status / brief / checklist / review md files — only `work/items/{ID}-{slug}/contract.md`.

## Routing

| User Intent | Route To |
|-------------|----------|
| Plan a work item | `/work-plan` |
| Implement (FEAT / FIX / PERF / CHORE / TEST) | `/work-impl` |
| Refactor (REFAC only) | `/work-refactor` |
| Review + merge | `/work-review` |
| Status | `/work-status` |
| Unattended Codex run | `bash codex-run.sh {ID}` |
| CI audit | `/gha-branch-sync` |

`/work-impl` runs `codex-run.sh` first by default and falls back to the current session if Codex stalls or leaves the contract unmet. Set `WORK_IMPL_SKIP_CODEX=1` to skip the Codex pass.

Re-entry (`reviewDecision=CHANGES_REQUESTED`) is handled inline: `/work-impl` and `/work-refactor` fetch unresolved review threads via GraphQL and treat each as a MUST-fix.

## References

- Rules: `collab-workflow.md`, `review-merge-policy.md`
- Config: `.claude/branch-map.yaml`
- Scripts: `codex-run.sh`, `lib/codex-run-*.sh`
- Templates: `.claude/templates/work-item/contract.md`
- Agents: `pr-reviewer`, `ci-audit-agent`
