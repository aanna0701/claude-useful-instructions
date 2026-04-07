---
name: collab-workflow
description: >
  Claude-Codex collaboration workflow for structured design-implement-review cycles.
  Triggers on: "work item", "work plan", "work review", "work status", "codex",
  "hand off", "delegate", "FEAT-", "REFAC-", "AUDIT-", "multi-agent", "parallel", "dispatch",
  "boundary check", "worktree", "link work", "concurrent", "branch map", "branch init",
  "branch status", "merge target", "trunk chain", "working parent", "CI audit", "gha sync",
  "workflow audit", "scaffold", "verify", "cursor", "cursor rules",
  "audit", "code audit", "consistency check", "verification result", "findings".
---

# Claude-Codex Collaboration Workflow

## Tool Assignments (Pipeline Roles)

| Command / Phase | Orchestrator | Executor | Description |
|-----------------|-------------|----------|-------------|
| `/collab-workflow {instruction}` | **Cursor / Antigravity** | Claude→You→Codex→You→Claude | Full pipeline with human gates |
| `/work-plan` | any | **Claude** | Decomposes tasks into sub-tasks and contracts |
| `/work-scaffold`| any | **Cursor / Antigravity** | Generates file structure and stubs |
| `/work-impl` | any | **Codex** | Implements code following contract |
| `/work-verify` | any | **Cursor / Antigravity** | Codebase audit and consistency checks |
| `/work-review` | any | **Claude** | Reviews implemented work |

## Routing

| User Intent | Route To |
|-------------|----------|
| **Full pipeline (Cursor/Antigravity)** | **`/collab-workflow {instruction}`** |
| Plan work item(s) | `/work-plan` |
| Check status | `/work-status` |
| Review + merge | `/work-review` |
| Set up branch hierarchy | `/branch-init` |
| Show branch state / freshness | `/branch-status` |
| Audit / fix / generate CI workflows | `/gha-branch-sync` |
| Scaffold file structure (standalone) | `/work-scaffold FEAT-NNN` or `/work-scaffold REFAC-NNN` |
| Codebase audit (standalone) | `/work-verify AUDIT-NNN` [→ `--ingest`] |
| Boundary check / dispatch | `codex-run.sh` (suggest command) |
| Implement in worktree | `/work-impl #<issue>` or `/work-impl FEAT-NNN` |
| Re-dispatch failed review | `/work-revise FEAT-NNN` |
| Code audit / consistency check | `/work-plan --type=audit` → `/work-verify AUDIT-NNN` |

## References

- Rule: `.claude/rules/collab-workflow.md`
- Rule: `.claude/rules/branch-map-policy.md`
- Rule: `.claude/rules/review-merge-policy.md`
- Config: `.claude/branch-map.yaml` (project branch hierarchy)
- Docs: `docs/collab-workflow.md` (full setup guide + walkthrough)
- Scripts: `codex-run.sh`
- Templates: `.claude/templates/work-item/`, `.claude/templates/branch-map/`, `.claude/templates/cursor/`
- Agent: `cursor-prompt-builder` (contract → Cursor/Antigravity prompt + rules assembly)
- Docs: `docs/cursor-integration.md` (Cursor/Antigravity integration guide)
- Pipeline steps (identical text): `.cursor/rules/collab-pipeline.mdc` and `.agent/workflows/collab-pipeline.md`, assembled by `install.sh` from `templates/collab-pipeline-body.md` in **claude-useful-instructions** (single source; do not edit the two installed copies by hand)
