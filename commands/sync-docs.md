# sync-docs — Sync project documentation to current codebase state

Analyze the current codebase state (including recent git changes and all dependency files) and update all `.md` documentation files to match reality.

Target files: $ARGUMENTS (if empty, update all stale `.md` files)

---

## Step 1: Scan current state (parallel)

Read all of the following in parallel:

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

Run these commands and analyze output:

```bash
git log --oneline -20
git diff HEAD~10..HEAD --stat
git diff HEAD~10..HEAD -- "*.toml" "*.txt" "requirements*" "package.json" "go.mod" "Cargo.toml"
git status --short
```

Extract from the diff:
- **New files added** since ~10 commits ago
- **Deleted files**
- **Dependency changes** (packages added/removed/upgraded)
- **Config changes** (ports, env vars, services)
- **Feature completion** (functions added, classes implemented)

---

## Step 3: Detect discrepancies

For each `.md` file, check against actual codebase AND git diff:

### Structure changes
- [ ] Source files not mentioned in docs?
- [ ] Files referenced in docs that no longer exist?
- [ ] New directories not documented?

### Dependency changes (from diff + current files)
- [ ] New packages in `requirements.txt` / `pyproject.toml` / `package.json` not in docs?
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

---

## Step 4: Determine update targets

If `$ARGUMENTS` is empty, update **all `.md` files** where changes were detected in Step 3.
If `$ARGUMENTS` specifies filenames or glob patterns, update only matching files.

Do not touch files where no changes were detected.

---

## Step 5: Per-file update rules

### Project metadata docs (README.md, CLAUDE.md)

- Reflect actual file list (remove deleted, add new)
- Update feature/status sections to match reality
- Update test counts from actual test sources
- Align build/install commands with actual dependency files
- Update dependency list from `requirements.txt` / `package.json` / `Cargo.toml`

### Plan/architecture docs (docs/PLAN.md, docs/TECH_STACK.md, etc.)

- Mark completed phases/tasks as done (reference git log for completion evidence)
- Update dependency lists to match current lock/spec files
- Flag any plan items contradicted by current code

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

---

## Step 7: Print summary

```
Documentation sync complete
─────────────────────────────────────────
Updated:  README.md (dependencies updated, 2 features added)
Updated:  docs/PLAN.md (3 tasks marked complete)
Updated:  docs/TECH_STACK.md (added kornia, removed opencv-python)
Skipped:  CONTRIBUTING.md (no changes detected)
─────────────────────────────────────────
Files scanned: N source, M docs
Dependencies scanned: requirements.txt, pyproject.toml
Git range: HEAD~10..HEAD (N commits)
Next: review updated files and commit
```
