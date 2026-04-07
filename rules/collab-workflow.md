# Claude-Codex Collaboration

## Roles

- **Claude**: spec owner, integrator — designs work items, reviews, merges, handles doc changes
- **Cursor**: structure propagator, verifier — scaffolds multi-file structures (Composer), verifies codebase consistency (Chat @Codebase)
- **Codex**: implementer — per contract only, never modifies docs (records in `status.md`)

## State Machine

```
planned → [scaffolded] → implementing → ready-for-review → reviewing → merged
             ↑ optional                                       ↓
             (skip OK)                                      revising

planned → auditing → audited   ← AUDIT type only (/work-verify → --ingest)
```

Valid transitions:
- `planned → scaffolded` — `/work-scaffold` (optional, Cursor integration)
- `planned → implementing` — `codex-run.sh` (direct, without scaffold)
- `scaffolded → implementing` — `codex-run.sh` (after Cursor scaffolding)
- `planned → auditing` — `/work-verify` (AUDIT type only)
- `auditing → audited` — manual or after Cursor @Codebase audit

Illegal shortcuts:
- `planned → reviewing` (must implement first)
- `implementing → merged` (must review first)
- `reviewing → implementing` (only via REVISE → `revising`)

## Ownership

- `working_parent` is orchestration-only. Never implement there.
- Feature worktrees are the only implementation workspace.
- `status.md` in the active worktree is authoritative while work is in progress.
- Contract = single source of truth for boundaries.

## Worktree-First File Resolution

Worktree copy is authoritative. Bootstrap: resolve slug → read `Worktree Path` from worktree `status.md` (`../${PROJECT}-${SLUG}/work/items/${SLUG}/status.md`) → fallback to cwd only if worktree absent. ALL subsequent reads use the resolved path.

## Locks

- `work/locks/planning.lock` — prevents concurrent `/work-plan`
- `work/locks/{ID}.lock` — prevents concurrent impl and review on same item
- `work/locks/merge.lock` — one merge-and-cleanup at a time

## Review Revision Policy

- Review fixes stay on the same work item via `/work-revise`.
- New work item only when refactoring exceeds contract boundary.
- On REVISE, every MUST-fix from `review.md` must be resolved before optional work.

## Principles

- Codex: code + `status.md` only — never docs; records doc needs in "Doc Changes Needed"
- `working_parent` is not a scratchpad. Keep clean before planning, review, and merge.
- Ambiguities recorded in `status.md`, never resolved by implementer
- Draft PR creation happens at implementation stage, not review stage
- Human intervention: dispatch + review only
- Cursor integration is optional — all workflows work without Cursor
- AUDIT type items skip implementation: `planned → auditing → audited`
- `/work-scaffold` and `/work-verify` auto-detect type from ID prefix (FEAT/REFAC/AUDIT)
- `/work-scaffold` generates `.cursor/rules/*.mdc` for glob-based contract enforcement
- `/work-verify` is AUDIT-only — FEAT/REFAC go directly to `/work-review`
