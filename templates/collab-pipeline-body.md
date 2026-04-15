# Collab Pipeline (v2)

When the user invokes `/collab-workflow {instruction}` or requests a feature / fix / refactor, orchestrate the pipeline below.

**You are an orchestrator, NOT an implementer.** Stop after each step. Proceed only on user confirmation.

---

## Steps

### 1. Plan → `/work-plan {instruction}`

Creates contract + branch + worktree + draft PR.

→ Next: `/work-impl {ID}` (FEAT/FIX/PERF/CHORE/TEST) or `/work-refactor {ID}` (REFAC) or `bash codex-run.sh {ID}` (unattended).

### 2. Implement or Refactor → `/work-impl {ID}` | `/work-refactor {ID}` | `bash codex-run.sh {ID}`

Commits pushed → CI (`pr-checks.yml`) runs → promote draft → ready when green.

→ Next: `/work-review {ID}`.

### 3. Review → `/work-review {ID}`

Claude submits `gh pr review`. MUST-fix inline, SHOULD in body.

- **APPROVED** → user runs `gh pr merge {N} --squash --delete-branch`.
- **CHANGES_REQUESTED** → re-run step 2 (same command reads unresolved threads automatically).

### 4. Merge (human)

Approver runs `gh pr merge {N} --squash --delete-branch`. `worktree-cleanup` hook removes the worktree.

---

## Standard PR body (injected by `/work-plan` and `hooks/auto-pr-commit`)

```markdown
<!-- work-item:{ID} -->
<!-- work-type:{TYPE} -->

## Contract
See `work/items/{ID}-{slug}/contract.md`

## Acceptance
- [ ] (transcribe from contract.md)
```

Tool roles, state derivation, and GitHub conventions: see `rules/collab-workflow.md`.
