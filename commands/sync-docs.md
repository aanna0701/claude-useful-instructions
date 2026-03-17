# sync-docs — Sync project documentation to current codebase state

Analyze the current codebase state (including git worktrees if present, recent git changes, and all dependency files) and update all `.md` documentation files to match reality.

Target files: $ARGUMENTS (if empty, update all stale `.md` files)

---

## Step 0: Discover worktrees (if any)

Check if the project uses git worktrees:

```bash
git worktree list
```

**If multiple worktrees exist** (multi-worktree mode):
- Parse the output to build a worktree map: `{ "<branch-name>": "<absolute-path>" }`
- The current working directory is the **docs worktree** (where docs changes are applied)
- All other worktrees are **code worktrees** (scanned for code changes, never modified)
- In Steps 1–2, scan ALL worktrees in parallel for a complete picture of the codebase

**If only one worktree exists** (single-repo mode):
- Skip this step entirely
- Proceed with Steps 1–2 scanning only the current directory

---

## Step 1: Scan current state (parallel)

For EACH worktree discovered in Step 0 (or just the current directory in single-repo mode), scan in parallel:

### Per-worktree scan
- **Source files** — `find . -name "*.py" -o -name "*.ts" -o ... | grep -v __pycache__ | sort` (module structure)
- **Test count** — `grep -r "def test_\|it(\|test(" tests/ --include="*.py" --include="*.ts" | wc -l`
- **Dependencies** — Read `pyproject.toml` / `package.json` / `Cargo.toml` / `go.mod`
- **Recent commits** — `git log --oneline -10`
- **Branch name** — `git branch --show-current`

### Docs worktree scan (current directory)
1. **File structure** — Glob `**/*.{cpp,h,sh,py,ts,js,yaml,yml,toml,json,proto,rs,go}`, `Makefile`, `Dockerfile*`, `docker-compose*.yml` — exclude `node_modules/`, `.venv/`, `**/googletest-*`, `dist/`, `build/`, `target/`
2. **All `.md` files** — Glob `**/*.md` (same exclusions)
3. **Dependency files** — Read every file that matches:
   - Python: `requirements*.txt`, `pyproject.toml`, `setup.py`, `setup.cfg`, `Pipfile`
   - Node: `package.json`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
   - Rust: `Cargo.toml`, `Cargo.lock`
   - Go: `go.mod`, `go.sum`
   - Ruby: `Gemfile`, `Gemfile.lock`
   - Generic: `*.toml`, `*.cfg`
4. **Build/CI files** — `Makefile`, `docker-compose*.yml`, `Dockerfile*`, `.github/workflows/*.yml`, `.gitlab-ci.yml`
5. **Test files** — All `test_*.py`, `*_test.py`, `*.test.ts`, `*.spec.ts`, `*_test.go`, `test_*.cpp` — count functions/macros
6. **CLI entry points** — Files with `argparse`, `click`, `typer`, `cobra`, `clap`, or `--` option parsing

---

## Step 2: Git diff analysis

For EACH worktree (or just current directory in single-repo mode), run:

```bash
cd $WT_PATH   # skip cd in single-repo mode
git log --oneline -20
git diff HEAD~10..HEAD --stat
git diff HEAD~10..HEAD -- "*.toml" "*.txt" "requirements*" "package.json" "go.mod" "Cargo.toml"
git status --short
```

Extract from the diffs:
- **New files added** on any branch/worktree
- **Deleted files**
- **Dependency changes** (packages added/removed/upgraded)
- **Config changes** (ports, env vars, services)
- **Feature completion** (functions added, classes implemented)
- **New modules** that need documentation

---

## Step 3: Detect discrepancies

For each `.md` file, check against **actual codebase across all worktrees**:

### Structure changes
- [ ] Source files in any worktree not mentioned in docs?
- [ ] Files referenced in docs that no longer exist on any worktree?
- [ ] New directories/modules not documented?

### Dependency changes (from all worktrees)
- [ ] New packages in any worktree's dependency files not in docs?
- [ ] Removed packages still mentioned in docs?
- [ ] Version pins changed?

### Configuration changes
- [ ] Build targets differ from docs?
- [ ] Docker services changed?
- [ ] Environment variables added/removed?
- [ ] CLI options changed?

### Implementation status
- [ ] Code changes not reflected in status/plan docs?
- [ ] Completed tasks still marked as TODO?
- [ ] New features not documented?

### Cross-worktree consistency (multi-worktree mode only)
- [ ] Each worktree's modules match their docs descriptions?
- [ ] Test counts accurate across all worktrees?
- [ ] Worktree-specific modules properly documented?

---

## Step 4: Determine update targets

If `$ARGUMENTS` is empty, update **all `.md` files** where changes were detected in Step 3.
If `$ARGUMENTS` specifies filenames or glob patterns, update only matching files.

Do not touch files where no changes were detected.

---

## Step 5: Per-file update rules

### Project metadata docs (README.md, CLAUDE.md)

- Reflect actual file list from **all worktrees** (remove deleted, add new)
- Update feature/status sections to match reality
- Update test counts from actual test sources (use the worktree with the most tests in multi-worktree mode)
- Align build/install commands with actual dependency files
- Update dependency list from dependency files across worktrees

### Plan/architecture docs (docs/plan.md, docs/tech-stack.md, etc.)

- Mark completed phases/tasks as done (reference git log for completion evidence)
- Update dependency lists to match current lock/spec files
- Flag any plan items contradicted by current code

### Module docs (docs/modules/*.md)

- Update module structure trees to match actual code on the relevant worktree
- Update API examples if interfaces changed
- Update test commands and test counts

### Operational docs (RUNBOOK.md, CONTRIBUTING.md)

- Update command tables to match actual CLI options
- Update setup instructions to match current dependency files
- Update alias/shortcut tables

### CODEMAPS (docs/CODEMAPS/*.md)

- Overwrite only if change rate > 30%; otherwise Edit specific sections
- Update metadata header: `<!-- Generated: YYYY-MM-DD | Files scanned: N -->`

### Subproject docs (e.g., env/frame_sync/README.md)

- Sync with subproject's actual state
- Ensure paths are correct relative to the subproject

---

## Step 6: Apply updates

For each file determined in Step 4, apply edits using the Edit tool.

Rules:
- Replace only auto-generated sections (`<!-- AUTO-GENERATED -->`); preserve hand-written prose
- Edit only changed portions — do not rewrite entire files
- Preserve UTF-8 encoding
- Do not add emojis unless already present in the file
- All changes go to the docs worktree only (in multi-worktree mode)

---

## Step 7: Print summary

### Single-repo mode
```
Documentation sync complete
─────────────────────────────────────────
Updated:  README.md (dependencies updated, 2 features added)
Updated:  docs/plan.md (3 tasks marked complete)
Updated:  docs/tech-stack.md (added kornia, removed opencv-python)
Skipped:  CONTRIBUTING.md (no changes detected)
─────────────────────────────────────────
Files scanned: N source, M docs
Dependencies scanned: requirements.txt, pyproject.toml
Git range: HEAD~10..HEAD (N commits)
Next: review updated files and commit
```

### Multi-worktree mode
```
Documentation sync complete (cross-worktree)
─────────────────────────────────────────
Worktrees discovered: N
  [docs]  /path/to/docs-wt        branch-name  (current)
  [code]  /path/to/code-wt-1      branch-name  (X tests, Y files)
  [code]  /path/to/code-wt-2      branch-name  (X tests, Y files)

Updated:  README.md (dependencies updated, 2 features added)
Updated:  docs/plan.md (3 tasks marked complete)
Skipped:  CONTRIBUTING.md (no changes detected)
─────────────────────────────────────────
Files scanned: N source, M docs
Max test count: Z (from branch-name)
Dependencies scanned: pyproject.toml × N worktrees
Next: review updated files and commit
```
