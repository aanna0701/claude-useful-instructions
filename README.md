# claude-useful-instructions

Portable Claude Code configuration. One `./install.sh` to apply everywhere.

## Layered Structure

```
┌──────────────────────────────────────────────────────────────┐
│  domain-*     docs · dl · career · google-style · presen-    │
│               tation · ppt-generation · data-pipeline        │
├──────────────────────────────────────────────────────────────┤
│  workflow     Local work-item flow (no PR, no CI)            │
│               (work items, CLAUDE.md, .work/contracts/,      │
│                local review + squash-merge policy)           │
├──────────────────────────────────────────────────────────────┤
│  base         git hooks + commit/push helpers                │
│               + token/debug utilities + pre-commit template  │
└──────────────────────────────────────────────────────────────┘
```

Every bundle installs into a target project's `.claude/` (and optionally `.cursor/`, `.agent/`, project root). A global shared config lives under `~/.claude/`.

## Quick Start

```bash
git clone https://github.com/aanna0701/claude-useful-instructions.git
cd claude-useful-instructions

# Typical: base + workflow per project
./install.sh --base --workflow /path/to/my-project

# Add a domain when needed
./install.sh --base --workflow --dl /path/to/ml-project

# Install everything
./install.sh /path/to/project
```

### Alias (optional)

```bash
CUI_DIR=~/claude-useful-instructions
echo "alias cui-install='$CUI_DIR/install.sh'" >> ~/.bashrc
source ~/.bashrc

cui-install --list
cui-install --base --workflow /path/to/project
```

## Bundle Matrix

| Layer    | Bundle            | Profile requires       | Contents                                                                                     |
|----------|-------------------|------------------------|----------------------------------------------------------------------------------------------|
| base     | `base`            | _(any)_                | `branch-naming`, `guard-branch`, `worktree-cleanup` hooks; `smart-git-commit-push`, `optimize-tokens`, `debug-guide`, `what-to-do` commands & agents; token analyzers; `.pre-commit-config.yaml` (variant auto-picked: `local-uv` for uv projects, `external-mirrors` otherwise) |
| workflow | `workflow`        | _(any)_                | Local work-item flow (`/work-plan`, `/work-impl`, `/work-refactor`, `/work-review`, `/work-status`), `collab-workflow` skill, `templates/work-item/contract.md`, `CLAUDE.md`. **No GitHub PRs, no Actions** — `.work/contracts/{ID}-{slug}/` replaces the PR. |
| domain   | `docs`            | _(any)_                | `diataxis-doc-system`, `diagram-architect` skills + doc/diagram agents + `/write-doc`, `/init-docs`, `/sync-docs` (v2: GitNexus + Starlight), `/polish-doc` |
| domain   | `data-pipeline`   | `python` + `ml-gpu`    | `data-pipeline-architect` skill                                                              |
| domain   | `codebase`        | _(any)_                | `codebase-qa` skill + `codebase-researcher` agent + `/codebase-ask` (GitNexus-backed)        |
| domain   | `career`          | _(any)_                | `career-docs` skill + writer/reviewer/reviser agents                                         |
| domain   | `dl`              | `python` + `ml-gpu`    | `pytorch-dl-standards` rules + DL agents (`capture`, `data`, `model`, `train`, `eval`, `infra`) |
| domain   | `presentation`    | `presentation`         | `html-presentation` skill + slide commands + `scripts/html_to_pdf.py` PDF export             |
| domain   | `ppt-generation`  | `presentation`         | PPT template-based generation (`/generate-ppt`, density/format agents)                       |
| domain   | `google-style`    | `python` or `cpp`      | Google C++/Python Style Guide rules + skill + `/refactor-google-style` + agents + `.clang-format` |

`detect_project_profile` tags the target from actual files (`pyproject.toml`, `uv.lock`, `astro.config.mjs`, `package.json`, CUDA in `docker-compose*.yml`, `CMakeLists.txt`, `Cargo.toml`, `go.mod`, HTML/PDF references). Bundles whose requirements don't intersect the profile are auto-skipped from `--all` and default installs. To install anyway, pass the explicit `--<bundle>` flag — explicit naming always wins.

## Install Options

```bash
./install.sh --list                                     # show bundles
./install.sh --all /path/to/project                     # install everything
./install.sh --base --workflow /path/to/project         # typical
./install.sh --exclude dl /path/to/project              # all except dl
./install.sh --interactive /path/to/project             # menu

./install.sh --uninstall /path/to/project               # remove all
./install.sh --uninstall --workflow /path/to/project    # remove workflow only
```

Breaking change: the old `--core` and `--collab` flags are **removed**. Use `--base` and `--workflow`.

---

## base layer — git workflow hooks

The `base` bundle installs the strict worktree-based git workflow:

```
Code edit on main repo
  → guard-branch blocks it
  → creates worktree (feature-adhoc-{MMDD-HHMM})
  → redirects edit to worktree

Commit in worktree
  → standard `git commit` (no PR, no push triggered automatically)

Local merge into parent
  → `git merge --squash` from the main worktree
  → worktree-cleanup deletes merged worktree + local branch
    (and remote branch if `origin` exists)
```

### Branch convention

| Type     | Pattern                        | Example                       |
|----------|--------------------------------|-------------------------------|
| feat     | `feature-{slug}`               | `feature-user-auth`           |
| fix      | `feature-fix-{slug}`           | `feature-fix-login-crash`     |
| refac    | `feature-refac-{slug}`         | `feature-refac-db-schema`     |
| docs     | `feature-docs-{slug}`          | `feature-docs-api-guide`      |
| perf     | `feature-perf-{slug}`          | `feature-perf-query-cache`    |
| test     | `feature-test-{slug}`          | `feature-test-auth-fuzz`      |
| chore    | `feature-chore-{slug}`         | `feature-chore-bump-deps`     |
| audit    | `feature-audit-{slug}`         | `feature-audit-ci-topology`   |
| adhoc    | `feature-adhoc-{slug}`         | `feature-adhoc-0408-1530`     |

`adhoc` is auto-created by `guard-branch` with a `MMDD-HHMM` stamp; manual slugs are also accepted. Enforced by `hooks/branch-naming`.

### Hooks

| Hook              | Event                          | What it does                                                 |
|-------------------|--------------------------------|--------------------------------------------------------------|
| `branch-naming`   | PreToolUse (Bash)              | Blocks non-`feature-*` branch names                          |
| `guard-branch`    | PreToolUse (Edit/Write)        | Redirects code edits to a feature worktree (no PR)           |
| `worktree-cleanup`| PostToolUse (Bash) + Stop      | After `git merge`: deletes merged worktrees, local + remote branches, and `.work/contracts/{ID}-{slug}/` |

### Pre-commit template (two variants, auto-picked)

Shipped as part of `base`. cui-install picks a variant based on the target project and installs it unconditionally at `.pre-commit-config.yaml`:

| Variant           | Condition                                                              | Python hooks source                                      |
|-------------------|------------------------------------------------------------------------|----------------------------------------------------------|
| `local-uv`        | `uv.lock` present, or `pyproject.toml` has `[tool.uv]` / `[dependency-groups]` | `repo: local` + `entry: uv run ...` — `uv.lock` is SSOT |
| `external-mirrors`| otherwise                                                              | pinned `rev:` on `ruff-pre-commit` / `mirrors-mypy` / `pyright-python` |

Both variants share C++ and general hooks (clang-format, trailing-whitespace, end-of-file-fixer, check-yaml, check-added-large-files).

| Language | Format      | Lint | Type          |
|----------|-------------|------|---------------|
| Python   | ruff-format | ruff | pyright, mypy |
| C++      | clang-format| —    | —             |
| General  | end-of-file-fixer, trailing-whitespace | check-yaml, check-added-large-files (≤1000 kB) | — |

Variants live under `templates/pre-commit/variants/`. Adding a new variant (e.g. for Poetry, Hatch, or pip-tools projects) means dropping a `.yaml` file there and teaching `_select_pre_commit_variant` to pick it — not forking this repo per-project.

cui-install **overwrites** `.pre-commit-config.yaml` on every run. Per-project divergence is not supported as a design decision: if a project shape needs a different variant, contribute the variant upstream rather than diverge locally. This also applies to `script:*` installs: each `.py` script is rewritten on every run and post-processed by the target project's own `ruff format`/`ruff check --fix` if `pyproject.toml` declares `[tool.ruff]`, so the installed version conforms to the target's lint rules even when CUI's own ruff settings differ.

---

## workflow layer — local work-item workflow (no PR)

`.work/contracts/` + git are the single source of truth. **No GitHub PRs, no Actions, no `gh` calls.**

```
/work-plan ──▶ /work-impl | /work-refactor ──▶ /work-review ──▶ (APPROVE → squash-merge + rm contract)
                       ▲                              │
                       └────── CHANGES_REQUESTED ─────┘
```

- **5 commands, 0 flags**: `/work-plan`, `/work-impl`, `/work-refactor`, `/work-review`, `/work-status`
- **1 directory per work item**: `.work/contracts/{ID}-{slug}/` — `contract.md` (spec), `.ready` (sentinel), `review-{sha}.md` (one per review pass). The whole `.work/` tree is gitignored.
- **State is derived** from `.work/contracts/` + `git worktree list` + branch ancestry
- **No CI**: pre-commit is the only automated gate. The user opted out of GitHub Actions to control cost.
- **Squash merge only**, performed locally by `/work-review` on APPROVE. APPROVE = squash-merge + `rm -rf .work/contracts/{ID}-{slug}/` (= "PR close").
- Optional `git push` keeps a remote mirror, but no PR is opened.

Executor is always Claude Code in-session. Cursor and Codex paths were removed.

---

## domain layer — task-specific bundles

| Bundle           | Trigger examples (skills auto-fire)                                  |
|------------------|---------------------------------------------------------------------|
| `docs`           | "Write docs", "Design doc", "API docs", "Draw diagram", "ERD", "Sync docs" — `/sync-docs` v2 auto-detects Starlight wiki and GitNexus code index for code-level doc sync |
| `data-pipeline`  | "Design data pipeline", "ETL architecture"                          |
| `codebase`       | "what breaks if I change X", "who calls Y", "blast radius", "이 함수 바꾸면 뭐 깨져?" — `/codebase-ask`, GitNexus required |
| `career`         | "자소서 써줘", "Cover letter", "경력기술서"                          |
| `dl`             | PyTorch DL standards; manual invocation of DL agents                |
| `presentation`   | "PPT format", "Slide conversion", "format-presentation"             |
| `ppt-generation` | "템플릿에 내용 넣어줘", "fill template", ".potx"                    |
| `google-style`   | `/refactor-google-style` command                                     |

Install only the domains you need. Domain bundles are independent of each other.

### GitNexus setup (optional — enhances `/sync-docs`)

GitNexus indexes your codebase into a knowledge graph (symbols, call chains, clusters, processes). When available, `/sync-docs` v2 uses it for code-level documentation sync instead of file-level diffs.

```bash
# 1. Install
npm install -g gitnexus

# 2. Register as MCP server for Claude Code
claude mcp add gitnexus -- npx -y gitnexus@latest mcp

# 3. Index a project (run from project root)
cd /path/to/your-project
gitnexus analyze

# 4. (Optional) Skip embeddings for faster indexing
gitnexus analyze --skip-embeddings
```

Add `.gitnexus/` to your project's `.gitignore`:
```bash
echo '.gitnexus/' >> .gitignore
```

`/sync-docs` auto-detects GitNexus — no flags needed. Without it, sync falls back to git-diff-based analysis.

| With GitNexus | Without |
|---|---|
| "function `train()` added `optimizer` param, callers updated — regenerate training-config.md from actual code" | "trainer.py changed — update docs that reference it" |

Re-index after major changes: `gitnexus analyze`. Stale index (>24h) triggers a warning.

---

## Reference

| Group               | Catalog                                                                                 |
|---------------------|-----------------------------------------------------------------------------------------|
| Skills              | [docs/skills.md](docs/skills.md)                                                        |
| Agents              | [docs/agents.md](docs/agents.md)                                                        |
| Commands            | [docs/commands.md](docs/commands.md)                                                    |
| Workflow architecture | [docs/collab-workflow.md](docs/collab-workflow.md)                                    |

## Project structure

```
claude-useful-instructions/
├── skills/           # Auto-triggered skills (diataxis, diagram, data-pipeline, codebase-qa,
│                     #   collab-workflow, html-presentation, career-docs, ppt-generation,
│                     #   google-style-refactor)
├── agents/           # Subagents (doc writers, diagram writer, debug-guide, token analyzers,
│                     #   codebase-researcher, dl-*, career-docs-*,
│                     #   ppt-*, google-style-*)
├── commands/         # Slash commands (/work-*, /write-doc, /init-docs, /sync-docs, /codebase-ask,
│                     #   /smart-git-commit-push, /optimize-tokens, /debug-guide, /what-to-do,
│                     #   /create-presentation, /format-presentation, /export-pdf, /generate-ppt,
│                     #   /refactor-google-style)
├── rules/            # Code standards (collab-workflow.md, review-merge-policy.md,
│                     #   pytorch-dl-standards.md, google-style-*.md)
├── hooks/            # Claude Code hooks (branch-naming, guard-branch, worktree-cleanup)
├── templates/        # Installable templates (pre-commit, work-item, claude/)
├── scripts/          # Utility scripts (html_to_pdf.py, patch-hook-settings.py)
├── lib/              # Shared helpers (merge-lock.sh)
├── docs/             # Reference guides
└── install.sh        # Bundle-based installer (+ --uninstall)
```

## Adding new configuration

1. Add files to `skills/`, `agents/`, `commands/`, `rules/`, or `hooks/`.
2. Register in `install.sh` under the appropriate `BUNDLE_*` array.
3. `git commit && git push`.
4. On other machines: `git pull && ./install.sh …`.
