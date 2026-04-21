# claude-useful-instructions

Portable Claude Code configuration. One `./install.sh` to apply everywhere.

## Layered Structure

```
┌──────────────────────────────────────────────────────────────┐
│  domain-*     docs · dl · career · google-style · presen-    │
│               tation · ppt-generation · data-pipeline        │
├──────────────────────────────────────────────────────────────┤
│  workflow     Claude-Codex collaboration                     │
│               (work items, AGENTS.md/CLAUDE.md, codex-run,   │
│                CI workflows, review/merge policy)            │
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

| Layer    | Bundle            | Contents                                                                                     |
|----------|-------------------|----------------------------------------------------------------------------------------------|
| base     | `base`            | `git-auto-pull`, `branch-naming`, `guard-branch`, `guard-merge`, `auto-pr-commit`, `auto-pr`, `worktree-cleanup` hooks; `smart-git-commit-push`, `optimize-tokens`, `debug-guide`, `what-to-do` commands & agents; token analyzers; `pre-commit` template |
| workflow | `workflow`        | Claude-Codex-Cursor work items (`/work-plan`, `/work-impl`, `/work-refactor`, `/work-review`, `/work-status`), `collab-workflow` skill, `pr-reviewer` / `ci-audit-agent`, CI (`pr-checks.yml`, `branch-auto-sync.yml`, `safe-branch-cleanup.yml`), `codex-run.sh`, `AGENTS.md`, `CLAUDE.md` |
| domain   | `docs`            | `diataxis-doc-system`, `diagram-architect` skills + doc/diagram agents + `/write-doc`, `/init-docs`, `/sync-docs` (v2: GitNexus + Starlight), `/polish-doc` |
| domain   | `data-pipeline`   | `data-pipeline-architect` skill                                                              |
| domain   | `codebase`        | `codebase-qa` skill + `codebase-researcher` agent + `/codebase-ask` (GitNexus-backed)        |
| domain   | `career`          | `career-docs` skill + writer/reviewer/reviser agents                                         |
| domain   | `dl`              | `pytorch-dl-standards` rules + DL agents (`capture`, `data`, `model`, `train`, `eval`, `infra`) |
| domain   | `presentation`    | `html-presentation` skill + slide commands + PDF export                                      |
| domain   | `ppt-generation`  | PPT template-based generation (`/generate-ppt`, density/format agents)                       |
| domain   | `google-style`    | Google C++/Python Style Guide rules + skill + `/refactor-google-style` + agents + `.clang-format` |

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

First commit in worktree
  → auto-pr-commit pushes branch + creates draft PR
    (body injected from templates/collab-pipeline-body.md)

PR merged (local or remote)
  → git-auto-pull fast-forwards the main worktree
  → worktree-cleanup deletes merged worktree + local + remote branch
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
| `guard-branch`    | PreToolUse (Edit/Write)        | Redirects code edits to worktree + creates Issue             |
| `guard-merge`     | PreToolUse (Bash/MCP merge)    | Blocks automated merges into protected branches              |
| `auto-pr-commit`  | PostToolUse (Bash)             | Draft PR on first `git commit`                               |
| `worktree-cleanup`| PostToolUse (Bash) + Stop      | Deletes merged worktrees + remote branches                   |
| `auto-pr`         | Stop                           | Fallback PR creation if `auto-pr-commit` missed              |
| `git-auto-pull`   | PreToolUse (Edit/Write) + PostToolUse (Bash/MCP merge) | Session-start pull + post-merge fast-forward        |

### Pre-commit template

| Language | Format      | Lint | Type          |
|----------|-------------|------|---------------|
| Python   | ruff-format | ruff | pyright, mypy |
| C++      | clang-format| —    | —             |
| General  | end-of-file-fixer, trailing-whitespace | check-yaml, check-added-large-files (≤1000 kB) | — |

---

## workflow layer — Claude-Codex collaboration

PR + git are the single source of truth. No markdown file stores state.

```
/work-plan (Claude) ──▶ /work-impl | /work-refactor (session AI) ──(push → CI)──▶ /work-review (Claude) ──▶ merge
                        ▲                                                                  │
                        └─────────────────────── CHANGES_REQUESTED ────────────────────────┘
```

- **5 commands, 0 flags**: `/work-plan`, `/work-impl`, `/work-refactor`, `/work-review`, `/work-status`
- **1 file per work item**: `work/items/{ID}-{slug}/contract.md` (immutable after plan)
- **State is derived** from `gh pr list` + `git worktree list`
- **CI required**: `pr-checks.yml` (ruff + mypy + pytest) bundled and installed automatically
- **Squash merge only**. MUST-fix = inline review comments, resolved via GraphQL `resolveReviewThread`
- **Two verification layers**: pre-commit (local, fast) + CI (remote, full) — intentional overlap

### `/work-impl` execution model

Three interchangeable executors, each reading the same inputs (contract + unresolved review threads + diff):

1. **Claude session** (`/work-impl` from `.claude/commands/`) — tries Codex first via `codex-run.sh` (unattended file edits only), then commits + pushes + handles PR state. Falls back to finishing in-session if Codex stalls.
2. **Cursor session** (`/work-impl` from `.cursor/commands/`) — open the worktree in Cursor, run the command; Composer/Agent performs coordinated multi-file edits and commits. Best for single-item interactive work.
3. **Unattended Codex** (`bash codex-run.sh {ID}`) — headless, ideal for running many independent items in parallel.

Single-responsibility across the board: the executor generates/edits; commit/push/PR state is the implementer's own `git` flow.

Migrating from v1? See [docs/MIGRATION-v2.md](docs/MIGRATION-v2.md). Rollback tag: `v1-final`.

### GitHub CLI (required)

```bash
# Ubuntu/Debian: sudo apt install gh
# macOS:        brew install gh
# Conda:        conda install gh --channel conda-forge
gh auth login
```

The workflow layer has **no fallback** for `gh` failures — they raise errors.

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
| v1 → v2 migration   | [docs/MIGRATION-v2.md](docs/MIGRATION-v2.md)                                            |

## Project structure

```
claude-useful-instructions/
├── skills/           # Auto-triggered skills (diataxis, diagram, data-pipeline, codebase-qa,
│                     #   collab-workflow, html-presentation, career-docs, ppt-generation,
│                     #   google-style-refactor)
├── agents/           # Subagents (doc writers, diagram writer, debug-guide, token analyzers,
│                     #   codebase-researcher, pr-reviewer, ci-audit-agent, dl-*, career-docs-*,
│                     #   ppt-*, google-style-*)
├── commands/         # Slash commands (/work-*, /write-doc, /init-docs, /sync-docs, /codebase-ask,
│                     #   /smart-git-commit-push, /optimize-tokens, /debug-guide, /what-to-do,
│                     #   /create-presentation, /format-presentation, /export-pdf, /generate-ppt,
│                     #   /refactor-google-style)
├── rules/            # Code standards (collab-workflow.md, review-merge-policy.md,
│                     #   pytorch-dl-standards.md, google-style-*.md)
├── hooks/            # Claude Code hooks — base layer (git-auto-pull, branch-naming,
│                     #   guard-branch, guard-merge, auto-pr-commit, auto-pr, worktree-cleanup)
├── templates/        # Installable templates (pre-commit, work-item, workflows, codex/claude/)
├── scripts/          # Utility scripts (html_to_pdf.py, patch-hook-settings.py)
├── lib/              # Shared helpers (merge-lock.sh)
├── docs/             # Reference guides
├── install.sh        # Bundle-based installer (+ --uninstall)
└── codex-run.sh      # Unattended Codex runner (edits only; Claude owns git/PR)
```

## Adding new configuration

1. Add files to `skills/`, `agents/`, `commands/`, `rules/`, or `hooks/`.
2. Register in `install.sh` under the appropriate `BUNDLE_*` array.
3. `git commit && git push`.
4. On other machines: `git pull && ./install.sh …`.
