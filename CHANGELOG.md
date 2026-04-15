# Changelog

## v2.0.0 — PR-native workflow (upcoming)

Complete redesign. State is derived from GitHub PR + git, never stored in md.

### Breaking changes
- Pipeline reduced to 4 stages: `plan → impl | refactor → review → merge`
- Commands reduced to 5: `/work-plan`, `/work-impl`, `/work-refactor`, `/work-review`, `/work-status`. All flag-free.
- Removed commands: `/work-scaffold`, `/work-revise`, `/work-verify`
- Per work item, only one file: `work/items/{ID}-{slug}/contract.md`
- Deleted per-item files: `status.md`, `brief.md`, `checklist.md`, `relay.md`, `pr-relay.md`, `verify-result.md`, `review.md`, `{slug}-guard.mdc`, `{slug}-forbidden.mdc`
- Merge strategy: squash only
- CI required (bundled as `pr-checks.yml`: ruff + mypy + pytest for Python)
- Branch naming: `feature-{TYPE}-{slug}` only; legacy `feature-{slug}` rejected
- `codex-run.sh` rewritten: no md writes, prompt = contract + unresolved review threads + diff

### Migration
- Rollback tag: `v1-final`
- Migration script: `scripts/migrate-v1-to-v2.sh` (dry-run default, `--apply` to execute)
- See `docs/MIGRATION-v2.md`
