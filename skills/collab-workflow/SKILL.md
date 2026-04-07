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

| Command / Phase | Primary Tool | Description |
|-----------------|--------------|-------------|
| `/work-plan` | **Claude** | Decomposes tasks into sub-tasks and contracts. |
| `/work-scaffold`| **Cursor / Antigravity** | Generates file structure, stubs, and boundary configuration. |
| `/work-impl` | **Codex** | Implements code following the contract parameters. |
| `/work-verify` | **Cursor / Antigravity** | Performs code audit and codebase consistency checks. |
| `/work-review` | **Claude** | Reviews implemented work and applies changes. |

## Routing

| User Intent | Route To |
|-------------|----------|
| Plan work item(s) | `/work-plan` |
| Check status | `/work-status` |
| Review + merge | `/work-review` |
| Set up branch hierarchy | `/branch-init` |
| Show branch state / freshness | `/branch-status` |
| Audit / fix / generate CI workflows | `/gha-branch-sync` |
| Cursor/Antigravity pipeline (auto-orchestrated) | Open `work/**` in Cursor/Antigravity → `collab-pipeline.mdc` or `.agent/workflows/` activates |
| Scaffold file structure (Cursor/Antigravity) | `/work-scaffold FEAT-NNN` or `/work-scaffold REFAC-NNN` |
| Codebase audit (Cursor/Antigravity) | `/work-verify AUDIT-NNN` [→ `--ingest`] |
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
