# sync-docs — Sync Documentation to Current Codebase

Analyze current codebase state (including git worktrees, recent changes, dependency files) and update all `.md` files (both `docs/` and `work/`) to match reality.

Target: $ARGUMENTS (if empty, update all stale `.md` files)

---

## Step 0: Discover Worktrees

```bash
git worktree list
```

**Multiple worktrees** (multi-worktree mode):
- Build worktree map: `{ "<branch>": "<path>" }`
- Current directory = **docs worktree** (apply changes here only)
- Other worktrees = **code worktrees** (scan only, never modify)
- Steps 1-2 scan ALL worktrees in parallel

**Single worktree**: Skip this step, scan current directory only.

---

## Step 1: Scan Current State (parallel)

### Per-worktree scan
- **Source files** — Module structure (exclude `__pycache__`)
- **Test count** — Count `def test_`, `it(`, `test(` in test files
- **Dependencies** — Read `pyproject.toml` / `package.json` / `Cargo.toml` / `go.mod`
- **Recent commits** — `git log --oneline -10`
- **Branch** — `git branch --show-current`

### Docs worktree scan (current directory)
1. **File structure** — Glob source files (exclude `node_modules/`, `.venv/`, `dist/`, `build/`, `target/`)
2. **All `.md` files** — Glob `**/*.md` (same exclusions), including `work/**/*.md`
3. **Dependency files** — All `requirements*.txt`, `pyproject.toml`, `package.json`, lock files, etc.
4. **Build/CI files** — `Makefile`, `docker-compose*.yml`, `Dockerfile*`, CI workflow files
5. **Test files** — Count test functions/macros across all test files
6. **CLI entry points** — Files using `argparse`, `click`, `typer`, `cobra`, `clap`

---

## Step 2: Git Diff Analysis

Per worktree (or current directory in single mode):

```bash
git log --oneline -20
git diff HEAD~10..HEAD --stat
git diff HEAD~10..HEAD -- "*.toml" "*.txt" "requirements*" "package.json" "go.mod" "Cargo.toml"
git status --short
```

Extract: new/deleted files, dependency changes, config changes, feature completions, new modules needing docs.

---

## Step 3: Detect Discrepancies

Check each `.md` file against actual codebase (all worktrees):

- [ ] Source files not mentioned in docs?
- [ ] Files referenced in docs that no longer exist?
- [ ] New directories/modules not documented?
- [ ] New/removed packages not reflected in docs?
- [ ] Version pins changed?
- [ ] Build targets, Docker services, env vars, CLI options changed?
- [ ] Code changes not reflected in status/plan docs?
- [ ] Completed tasks still marked TODO?
- [ ] New features not documented?

### Execution artifact consistency (work/)
- [ ] `done` Tasks/Briefs without corresponding Review?
- [ ] `done` Work Item checklists with unchecked items?
- [ ] Briefs/Tasks referencing superseded/deleted Contracts or RFC/ADR?
- [ ] Orphaned Checklists (parent Brief/Task deleted)?
- [ ] Status.md mismatches code reality? (Work Item bundles)
- [ ] Work Item bundles missing required files (brief/contract/checklist/status)?
- [ ] Contract boundaries violated by actual code changes?

### Cross-worktree (multi-worktree only)
- [ ] Each worktree's modules match docs?
- [ ] Test counts accurate across worktrees?

---

## Step 4: Determine Update Targets

- `$ARGUMENTS` empty → update all `.md` files with detected changes
- `$ARGUMENTS` specified → update only matching files/patterns
- Skip files with no detected changes

---

## Step 5: Per-file Update Rules

### Project metadata (README.md, CLAUDE.md)
- Reflect actual file list from all worktrees
- Update feature/status sections, test counts, build commands, dependencies

### Plan/architecture docs
- Mark completed phases/tasks as done (evidence from git log)
- Update dependency lists from current lock/spec files
- Flag plan items contradicted by current code

### Module docs
- Update structure trees, API examples, test commands/counts

### Operational docs (RUNBOOK.md, CONTRIBUTING.md)
- Update CLI command tables, setup instructions, alias tables

### CODEMAPS
- Full rewrite if >30% change rate; otherwise edit specific sections
- Update metadata: `<!-- Generated: YYYY-MM-DD | Files scanned: N -->`

### Subproject docs
- Sync with subproject state; ensure correct relative paths

### Execution artifacts (work/)
- Update Brief/Task status from git evidence (merged feature branches → `done`)
- Sync Work Item status.md with actual branch/worktree state
- Flag orphaned Checklists, unused Contracts, missing Reviews
- Verify source links and FEAT-NNN/T-NNN references
- Detect Work Item bundles with stale status.md

---

## Step 6: Apply Updates

Use Edit tool for each target file.

Rules:
- Replace only auto-generated sections (`<!-- AUTO-GENERATED -->`); preserve hand-written prose
- Edit changed portions only — no full rewrites
- Preserve UTF-8 encoding
- No emoji additions unless already present
- All changes go to docs worktree only (multi-worktree mode)

---

## Step 7: Summary

### Single-repo mode
```
Documentation sync complete
─────────────────────────────────────────
Updated:  README.md (dependencies updated, 2 features added)
Updated:  docs/plan.md (3 tasks marked complete)
Skipped:  CONTRIBUTING.md (no changes detected)
─────────────────────────────────────────
Files scanned: N source, M docs
Dependencies: requirements.txt, pyproject.toml
Git range: HEAD~10..HEAD (N commits)
Next: review updated files and commit
```

### Multi-worktree mode
```
Documentation sync complete (cross-worktree)
─────────────────────────────────────────
Worktrees: N
  [docs]  /path/to/docs-wt        branch  (current)
  [code]  /path/to/code-wt-1      branch  (X tests, Y files)
  [code]  /path/to/code-wt-2      branch  (X tests, Y files)

Updated:  README.md (dependencies updated, 2 features added)
Updated:  docs/plan.md (3 tasks marked complete)
Skipped:  CONTRIBUTING.md (no changes detected)
─────────────────────────────────────────
Files scanned: N source, M docs
Max test count: Z (from branch)
Dependencies: pyproject.toml x N worktrees
Next: review updated files and commit
```
