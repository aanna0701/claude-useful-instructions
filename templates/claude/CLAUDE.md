# Project Instructions

## Collab Workflow (v2)

This project uses a PR-native collaboration workflow. State is derived from GitHub PR + git. No md file stores state.

SSOT: `.claude/rules/collab-workflow.md`.

### Pipeline

```
plan → impl | refactor → review → merge
              ▲              │
              └ CHANGES_REQUESTED
```

### Commands (flag-free)

- `/work-plan` — create item (contract + branch + worktree + draft PR)
- `/work-impl {ID}` — FEAT / FIX / PERF / CHORE / TEST
- `/work-refactor {ID}` — REFAC
- `/work-review {ID}` — `gh pr review` with inline MUST-fix
- `/work-status [ID]` — read-only, `gh` + `git` derived

Unattended: `bash codex-run.sh {ID}`.

### Per-item file

One file only: `work/items/{ID}-{slug}/contract.md`. No status / relay / review / checklist / brief.

### GitHub conventions

- Branch: `feature-{type}-{slug}`
- Merge: squash only
- MUST-fix: inline review comments (resolved via GraphQL `resolveReviewThread`)
- CI required: `.github/workflows/pr-checks.yml` (bundled)
- pre-commit (local) + CI (remote): intentional overlap

<!-- USER SECTION BELOW -->

## Code Standards

- All code and comments in English.
- Follow existing project conventions.
- Python: uv-managed (`uv run ...`).
- All commits signed: `git commit -s`.
