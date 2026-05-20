# claude-useful-instructions

Personal instruction library for Claude Code, with an auto-generated Codex compatibility layer.

## Platform model

- Claude is the source format.
- Codex artifacts are generated from Claude skills.
- Unsafe or ambiguous mappings stay unsupported until there is a deterministic conversion rule.

See [docs/codex-auto-generation.md](/home/leo/claude-useful-instructions/docs/codex-auto-generation.md) for the current Codex policy.

## Install

In any Claude Code session, on any machine:

```
/plugin marketplace add https://github.com/aanna0701/claude-useful-instructions
/plugin install claude-useful-instructions@claude-useful-instructions
```

This pulls the repo into `~/.claude/plugins/marketplaces/claude-useful-instructions/` and registers every entry under `skills/`, `agents/`, `commands/`, `hooks/`, and `rules/` at the user level.

## Codex generation

This repo now includes a conservative Codex build path for skills.

```bash
npm run validate:codex
npm run build:codex
```

Generated outputs:

- `.agents/skills/*/SKILL.md`
- `.agents/skills/*/agents/openai.yaml`
- `.codex/generated/skills-manifest.json`

Current scope:

- `skills/` are supported for automatic conversion
- `commands/`, `hooks/`, and `rules/` remain intentionally unsupported in the generator

### Per-project setup (run once per repo)

The plugin loads user-wide, but a few things still belong **in the target project**:

```
# Enable the worktree-redirect hook on this repo (opt-in marker)
touch .claude-worktree-enabled

# Enable the local work-item workflow (/work-plan, /work-impl, ...)
mkdir -p .work/contracts && grep -qxF '.work/' .gitignore || echo '.work/' >> .gitignore

# Scaffold .pre-commit-config.yaml (+ .clang-format if C/C++) — pick variant automatically
/setup-pre-commit
```

All three are no-ops on projects where you don't want them — they activate only when the corresponding marker / config exists. See [Per-project opt-ins](#per-project-opt-ins) and [Pre-commit](#pre-commit) for details.

### Update

After `git push` on this repo:

```
/plugin marketplace update claude-useful-instructions
```

### Uninstall

```
/plugin uninstall claude-useful-instructions@claude-useful-instructions
/plugin marketplace remove claude-useful-instructions
```

### Private mirror

The repo is public. If you fork to a private mirror, authenticate on the target machine first (`gh auth login` or SSH key) before `/plugin marketplace add`.

## What you get

A single bundled plugin exposing four layers:

```
┌──────────────────────────────────────────────────────────────┐
│  domain     docs · dl · career · google-style ·              │
│             data-pipeline · codebase                         │
├──────────────────────────────────────────────────────────────┤
│  workflow   Local work-item flow (no PR, no CI):             │
│             /work-plan /work-impl /work-refactor             │
│             /work-review /work-status                        │
├──────────────────────────────────────────────────────────────┤
│  base       git hooks + commit/push helpers + token/debug    │
│             utilities                                        │
├──────────────────────────────────────────────────────────────┤
│  rules      collab-workflow · review-merge-policy ·          │
│             pytorch-dl-standards · google-style-{cpp,python} │
└──────────────────────────────────────────────────────────────┘
```

### Contents catalog

| Group     | Items |
|-----------|-------|
| Skills    | `career-docs`, `codebase-qa`, `collab-workflow`, `data-pipeline-architect`, `dpipe-copilot`, `diagram-architect`, `diataxis-doc-system`, `google-style-refactor` |
| Agents    | Doc writers (`doc-writer-{explain,guide,reference,checklist,contract,task,review}`), `doc-reviewer`, `diagram-writer`, `codebase-researcher`, `debug-guide`, DL (`dl-{capture,data,model,train,eval,infra}`), career (`career-docs-{writer,reviewer,reviser}`), `dpipe-runner`, `google-style-refactor-*` |
| Commands  | `/work-plan`, `/work-impl`, `/work-refactor`, `/work-review`, `/work-status`, `/write-doc`, `/init-docs`, `/sync-docs`, `/polish-doc`, `/codebase-ask`, `/smart-git-commit-push`, `/optimize-tokens`, `/debug-guide`, `/what-to-do`, `/refactor-google-style`, `/setup-pre-commit` |
| Hooks     | `branch-naming`, `guard-branch`, `worktree-cleanup` |
| Rules     | `collab-workflow.md`, `review-merge-policy.md`, `pytorch-dl-standards.md`, `google-style-cpp.md`, `google-style-python.md`, `pre-commit-policy.md` |

Detailed reference:

| Group                 | Catalog                                         |
|-----------------------|-------------------------------------------------|
| Skills                | [docs/skills.md](docs/skills.md)                |
| Agents                | [docs/agents.md](docs/agents.md)                |
| Commands              | [docs/commands.md](docs/commands.md)            |
| Workflow architecture | [docs/collab-workflow.md](docs/collab-workflow.md) |

## Per-project opt-ins

A few features need a per-project marker because they alter the project's git workflow:

| Feature                       | Opt-in                                              |
|-------------------------------|-----------------------------------------------------|
| `guard-branch` worktree redirect | `touch .claude-worktree-enabled` in the repo root |
| `collab-workflow` (`/work-*`)    | `mkdir -p .work/contracts` and add `.work/` to `.gitignore` |

Without these markers, the corresponding hooks and commands stay dormant on that project. This is intentional: a user-level marketplace install should not silently change behavior of every repo on the machine.

## base layer — git workflow hooks

Strict worktree-based flow. When active in a project:

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

| Type   | Pattern                  | Example                     |
|--------|--------------------------|-----------------------------|
| feat   | `feature-{slug}`         | `feature-user-auth`         |
| fix    | `feature-fix-{slug}`     | `feature-fix-login-crash`   |
| refac  | `feature-refac-{slug}`   | `feature-refac-db-schema`   |
| docs   | `feature-docs-{slug}`    | `feature-docs-api-guide`    |
| perf   | `feature-perf-{slug}`    | `feature-perf-query-cache`  |
| test   | `feature-test-{slug}`    | `feature-test-auth-fuzz`    |
| chore  | `feature-chore-{slug}`   | `feature-chore-bump-deps`   |
| audit  | `feature-audit-{slug}`   | `feature-audit-ci-topology` |
| adhoc  | `feature-adhoc-{slug}`   | `feature-adhoc-0408-1530`   |

`adhoc` is auto-created by `guard-branch` with a `MMDD-HHMM` stamp; manual slugs are also accepted. Enforced by `hooks/branch-naming`.

### Hooks

| Hook              | Event                   | What it does                                                                                            |
|-------------------|-------------------------|---------------------------------------------------------------------------------------------------------|
| `branch-naming`   | PreToolUse (Bash)       | Blocks non-`feature-*` branch names                                                                     |
| `guard-branch`    | PreToolUse (Edit/Write) | Redirects code edits to a feature worktree (no PR). Opt-in via `.claude-worktree-enabled`               |
| `worktree-cleanup`| PostToolUse (Bash) + Stop | After `git merge`: deletes merged worktrees, local + remote branches, and `.work/contracts/{ID}-{slug}/` |

## workflow layer — local work-item workflow (no PR)

`.work/contracts/` + git are the single source of truth. **No GitHub PRs, no Actions, no `gh` calls.**

```
/work-plan ──▶ /work-impl | /work-refactor ──▶ /work-review ──▶ (APPROVE → squash-merge + rm contract)
                       ▲                              │
                       └────── CHANGES_REQUESTED ─────┘
```

- **5 commands, 0 flags**: `/work-plan`, `/work-impl`, `/work-refactor`, `/work-review`, `/work-status`
- **1 directory per work item**: `.work/contracts/{ID}-{slug}/` — `contract.md` (spec), `.ready` (sentinel), `review-{sha}.md` (one per review pass). The whole `.work/` tree must be gitignored.
- **State is derived** from `.work/contracts/` + `git worktree list` + branch ancestry.
- **No CI**: pre-commit is the only automated gate. Scaffold the per-project config on demand with `/setup-pre-commit` (see [Pre-commit](#pre-commit) below).
- **Squash merge only**, performed locally by `/work-review` on APPROVE. APPROVE = squash-merge + `rm -rf .work/contracts/{ID}-{slug}/` (= "PR close").
- Optional `git push` keeps a remote mirror, but no PR is opened.

Executor is always Claude Code in-session.

## domain layer — task-specific bundles

Domain skills auto-fire from natural-language triggers:

| Skill                    | Trigger examples                                                                                                |
|--------------------------|-----------------------------------------------------------------------------------------------------------------|
| `diataxis-doc-system`    | "Write docs", "Design doc", "API docs", "Draw diagram", "ERD" — drives `/write-doc`, `/init-docs`, `/sync-docs` |
| `data-pipeline-architect`| "Design data pipeline", "ETL architecture", "데이터 파이프라인 설계해줘" (design phase)                          |
| `dpipe-copilot`          | "파이프라인 다시 돌려줘", "stage 검증", "DB/스키마 확인", "산출물 재생성", "rerun pipeline" (ops phase)            |
| `codebase-qa`            | "what breaks if I change X", "who calls Y", "blast radius", "이 함수 바꾸면 뭐 깨져?" — drives `/codebase-ask`   |
| `career-docs`            | "자소서 써줘", "Cover letter", "경력기술서"                                                                       |
| `google-style-refactor`  | `/refactor-google-style` command                                                                                  |

`pytorch-dl-standards` (rules) and the `dl-*` agents are loaded but only act when invoked.

## Pre-commit

The plugin does **not** auto-install `.pre-commit-config.yaml` into your project — marketplace plugins live at user level and can't safely modify arbitrary repos. Instead it ships templates + a policy + a scaffolding command.

```
/setup-pre-commit
```

The command (see `commands/setup-pre-commit.md`):

1. Detects the project root (`git rev-parse --show-toplevel`).
2. Picks a variant per `rules/pre-commit-policy.md`:
   - `local-uv` if `uv.lock` exists or `pyproject.toml` declares `[tool.uv]` / `[dependency-groups]`.
   - `external-mirrors` otherwise.
3. Copies the chosen variant to `<project>/.pre-commit-config.yaml`, plus `.clang-format` if the project has C/C++ sources.
4. Runs `pre-commit install` and `pre-commit run --all-files` once.

| Variant            | When                                                                  | Python hook source                                          |
|--------------------|-----------------------------------------------------------------------|-------------------------------------------------------------|
| `local-uv`         | uv-managed Python projects (`uv.lock` present)                        | `repo: local` with `entry: uv run …` — `uv.lock` is SSOT    |
| `external-mirrors` | non-uv projects (pip, poetry, hatch, pip-tools, or non-Python)        | pinned `rev:` on `ruff-pre-commit`, `mirrors-mypy`, `pyright-python` |

Both share C++ (clang-format) and general hooks (trailing-whitespace, end-of-file-fixer, check-yaml, check-added-large-files ≤1000 kB).

Bumping tool versions is a marketplace-side change: edit the template, push, run `/plugin marketplace update claude-useful-instructions` on each machine, then re-run `/setup-pre-commit` per project.

Need a new variant (e.g., Poetry-specific)? Add `templates/pre-commit/variants/<name>.yaml` to this plugin and extend the table in `rules/pre-commit-policy.md`. Do not diverge per-project.

### GitNexus setup (optional — enhances `/sync-docs` and `/codebase-ask`)

GitNexus indexes your codebase into a knowledge graph. When available, `/sync-docs` v2 and `/codebase-ask` use it for code-level analysis instead of file-level diffs.

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

| With GitNexus | Without |
|---|---|
| "function `train()` added `optimizer` param, callers updated — regenerate training-config.md from actual code" | "trainer.py changed — update docs that reference it" |

Re-index after major changes: `gitnexus analyze`. Stale index (>24h) triggers a warning.

## Project structure

```
claude-useful-instructions/
├── .claude-plugin/
│   ├── marketplace.json   # /plugin marketplace add target
│   └── plugin.json        # plugin metadata
├── skills/                # Auto-triggered skills
├── agents/                # Subagents
├── commands/              # Slash commands
├── rules/                 # Code standards
├── hooks/                 # Claude Code hooks
├── templates/             # Templates referenced by skills/commands
│   ├── work-item/         #   used by /work-plan
│   ├── google-style/      #   used by /refactor-google-style
│   └── pre-commit/        #   used by /setup-pre-commit (local-uv + external-mirrors variants)
├── lib/                   # Shared shell helpers
│   └── merge-lock.sh      #   used by /work-review
├── docs/                  # Reference guides
├── CHANGELOG.md
└── README.md
```

## Adding new configuration

1. Add files to `skills/`, `agents/`, `commands/`, `rules/`, or `hooks/`.
2. `git commit && git push`.
3. On other machines: `/plugin marketplace update claude-useful-instructions`.

No registration step — the plugin loader picks up every file in those directories.
