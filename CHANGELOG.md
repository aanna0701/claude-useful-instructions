# Changelog

## Unreleased — marketplace-only distribution

### Breaking changes
- **Install path is now marketplace-only.** Use `/plugin marketplace add https://github.com/aanna0701/claude-useful-instructions` + `/plugin install claude-useful-instructions@claude-useful-instructions`.
- Removed `install.sh` and all bundle flags (`--base`, `--workflow`, `--dl`, `--all`, `--exclude`, `--interactive`, `--list`, `--uninstall`).
- Removed `scripts/patch-hook-settings.py` (install.sh helper).
- Removed `scripts/migrate-v1-to-v2.sh` (legacy v1→v2 migration script).
- Removed `templates/claude/` (project-level `CLAUDE.md` template — relevant only to install.sh).
- Removed `templates/pre-commit/` (per-project pre-commit template; configure externally per project).
- Removed `.claude/` snapshot from repo root (stale install artifact).

### Added
- `.claude-plugin/marketplace.json` + `.claude-plugin/plugin.json` — Claude Code marketplace metadata.

### Changed
- `hooks/guard-branch`: opt-in comment updated. Marker `.claude-worktree-enabled` is now created by hand (no more `install.sh --core` / `--collab`). Hook logic unchanged.
- README rewritten around the marketplace flow.

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
