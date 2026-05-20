# Commands Reference

Commands are user-invocable slash commands (`.md` files) shipped under `commands/` in this repo. After `/plugin install claude-useful-instructions@claude-useful-instructions`, Claude Code loads them user-wide; users type `/<command-name>` to trigger them.

---

## /work-plan

Create a local work item: contract + branch + worktree. **No GitHub PR, no GitHub Issue.**

**Usage**:
```
/work-plan <description>
```

Materializes `.work/contracts/{ID}-{slug}/contract.md` and creates `feature-{type}-{slug}` branch + worktree.

---

## /work-status

Check the progress of active work items.

**Usage**:
```
/work-status              # All active items
/work-status FEAT-001     # Specific item
```

---

## /work-review

Review a completed work item against its contract. Decides merge/revise/reject.

**Usage**:
```
/work-review FEAT-001
```

---

## /work-impl

Implement a work item (`FEAT`/`FIX`/`PERF`/`CHORE`/`TEST`) in its worktree. Reads `contract.md` + the latest `review-{shortSHA}.md` (if any) + `git diff $PARENT...HEAD`.

**Usage**:
```
/work-impl FEAT-001
```

Executor is always the current Claude Code session — there is no Cursor/Codex path.

---

## /work-refactor

Refactor a work item (`REFAC` only). Same inputs as `/work-impl`, but honors `Boundaries.Preserve` from the contract — no new public symbols, existing tests stay green.

**Usage**:
```
/work-refactor REFAC-007
```

---

## /write-doc

Diátaxis Framework-based technical document writing command.

**Usage**:
```
/write-doc [topic]              # Write a new document
/write-doc review [file path]   # Review an existing document
```

### Workflow

| Step | Action |
|------|--------|
| 0 | Mode detection: new doc or review |
| 1 | Gather input (topic, audience, purpose) |
| 2 | Classify document type (Tutorial / How-to / Explanation / Reference) |
| 3 | Delegate to matching `doc-writer-*` agent |
| 4 | Save to docs/ (auto-detects numbered or type-based structure) |
| 5 | Quality review (type purity, frontmatter, SSOT, governance) |
| 6 | Completion report |

### Docs Directory Structure

If `docs/00_context/` exists, uses the numbered scheme:
```
docs/
├── 00_context/          ← Explanation (business), Reference (requirements)
├── 10_architecture/     ← Explanation (design, ADR)
├── 20_implementation/   ← Reference (API, Config, CLI)
├── 30_guides/           ← Tutorial, How-to
└── 40_operations/       ← How-to (deploy, Runbook), Reference (SLA)
```

Otherwise, uses type-based structure (`tutorials/`, `howto/`, `explanation/`, `reference/`).

> Run `/init-docs` first to set up the numbered scheme.

---

## /init-docs

Scaffold a MkDocs-based docs site with numbered directory structure and Diátaxis integration.

**Usage**:
```
/init-docs              # Initialize in current directory
/init-docs /path/to/project
```

### What It Creates

```
docs/
├── index.md              # Doc home (project overview + doc map)
├── glossary.md           # Glossary (SSOT)
├── 00_context/           # Why this project
├── 10_architecture/      # Design decisions + ADR
│   └── adr/
├── 20_implementation/    # API/Config/CLI specs
├── 30_guides/            # Tutorials + How-to
│   ├── tutorials/
│   └── howto/
├── 40_operations/        # Deploy, monitoring, runbook
└── 90_archive/           # Deprecated docs

mkdocs.yml                # MkDocs Material config
.github/workflows/        # CI/CD (optional)
```

### Numbering Scheme

| Range | Category | Core Question |
|-------|----------|---------------|
| `00` | Context | **Why** this project? |
| `10` | Architecture | **How** to build it? (design) |
| `20` | Implementation | **What** was built? (code level) |
| `30` | Guides | **How** to use it? (practical) |
| `40` | Operations | **How** to run it? (production) |
| `50-80` | Reserved | Project-specific extensions |
| `90` | Archive | No longer valid docs |

---

## /sync-docs

Sync project documentation to the current codebase state. Uses specialized agents (Sonnet for mechanical tasks, Opus for code-understanding-based writing) and auto-detects available capabilities.

**Usage**:
```
/sync-docs              # Sync all stale documentation
/sync-docs README.md    # Sync specific file only
```

### Auto-detected Modes

| Feature | Detection | Effect |
|---|---|---|
| **Starlight** | `astro.config.mjs` + `@astrojs/starlight` import | Wiki pages (`src/content/docs/`) synced, sidebar report, dashboard data updated |
| **GitNexus** | MCP `list_repos` or `.gitnexus/` directory | Symbol-level blast radius analysis, semantic doc matching, code-based rewriting |
| **Multi-worktree** | `git worktree list` >1 entry | Cross-worktree scan |

### Agent Delegation

| Task | Agent | Why |
|---|---|---|
| Scan, diff, metadata, standard docs, dashboard | **Sonnet** | Mechanical collection and value replacement |
| Code understanding (GitNexus analysis) | **Opus** | Symbol relationship reasoning |
| Wiki page rewriting | **Opus** | Needs deep code understanding to write accurate docs |
| Architecture diagram regeneration | **Opus** | Process/cluster to mermaid conversion |

### Wiki Page Update Policy (Starlight)

| Page type | Policy |
|---|---|
| **Reference** (API, schema, config) | Aggressive rewrite from actual code |
| **Guide** (how-to, setup, workflow) | Preserve prose, update commands/values |
| **Explanation** (architecture, design) | Flag only, no auto-edit |

Page type inferred from: frontmatter `type` field > directory path > content patterns.

### Key Difference: GitNexus On vs Off

- **Without GitNexus**: file-level — "this file changed, update docs that reference it"
- **With GitNexus**: code-level — "this function's signature changed, its callers changed, regenerate the docs from what the code actually does now"

---

## /polish-doc

Apply writing-style and structural fixes directly to existing documents. Counterpart to `/write-doc` (creates) and `doc-reviewer` (suggests only).

**Usage**:
```
/polish-doc [filepath]              # Full polish (style + structure)
/polish-doc [filepath] --quick      # Quick polish (style only)
/polish-doc [glob-pattern]          # Multiple files
```

### Workflow

| Step | Action |
|------|--------|
| 1 | Read file, detect doc type from frontmatter or content |
| 2 | Show assessment (type, depth, estimated issues) |
| 3 | Delegate to `doc-polisher` agent |
| 4 | Completion report with per-file summary |

---

## /optimize-tokens

Analyze and reduce token waste in Claude Code instruction files (commands, agents, skills, rules).

**Usage**:
```
/optimize-tokens              # Scan all .claude/ files
/optimize-tokens cover-letter # Scan specific command and its dependencies
```

### Analysis Dimensions

| Check | What It Detects |
|-------|----------------|
| Cross-file duplication | Command ↔ Agent, Reference ↔ Agent, Rule ↔ Agent overlap |
| MCP call efficiency | Redundant queries, missing batches, upload-then-requery |
| Session token load | Total lines loaded per execution path, files loaded twice |
| Intra-file repetition | Same rule in multiple sections, verbose examples |

### Workflow

| Step | Action |
|------|--------|
| 1 | Inventory all instruction files with line counts |
| 2 | Cross-file duplication detection (>70% overlap) |
| 3 | MCP call mapping and efficiency analysis |
| 4 | Session load simulation per execution path |
| 5 | Prioritized report (critical / moderate / low) |
| 6 | Apply fixes with user confirmation |
| 7 | Summary with before/after metrics |

---

## /debug-guide

Analyze recent git commits and generate a prioritized verification/debug checklist.

**Usage**:
```
/debug-guide              # Analyze recent commits
/debug-guide 5            # Last 5 commits only
```

Reads diffs, detects risk patterns (error handling, concurrency, config changes), and produces a checklist sorted by risk level.

---

## /what-to-do

Review recent commits and generate an action plan: what to verify, debug, and implement next.

**Usage**:
```
/what-to-do               # Today's commits + previous session
/what-to-do 2026-04-01    # Since specific date
```

Categorizes next steps into: **Verify** (test what was built), **Debug** (investigate issues), **Implement** (continue work).

---

## /codebase-ask

Answer a question about the codebase using GitNexus MCP tools. Read-only — never edits code.

**Usage**:
```
/codebase-ask <question>
/codebase-ask <question> --focus=<area>
/codebase-ask <question> --deep
```

### Flags

| Flag | Effect |
|---|---|
| `--focus=<area>` | Area hint (e.g., `--focus=auth`, `--focus=training-pipeline`) |
| `--deep` | Force delegation to `codebase-researcher` even for simple questions |

### Workflow

| Step | Action |
|------|--------|
| 1 | Parse `$ARGUMENTS` → `QUESTION`, `FOCUS`, `DEEP` |
| 2 | Dispatch to `codebase-qa` skill (preflight + intent classify + direct-or-delegate) |
| 3 | Present skill answer; highlight `(unverified)` symbols or stale index at top |

If GitNexus isn't installed/indexed, the command prints setup instructions (`npm install -g gitnexus`, `claude mcp add gitnexus …`, `gitnexus analyze`). See [README.md](../README.md) "GitNexus setup" section.

---

## /smart-git-commit-push

Analyze changes, auto-split by feature into separate commits, and push.

**Usage**:
```
/smart-git-commit-push              # Commit + push to current branch
/smart-git-commit-push main         # Push to main branch
```

---

## /refactor-google-style

Apply the Google C++ / Python Style Guide across the repository. Orchestrates a mechanical formatting pass followed by semantic rewrites via language-specific agents.

**Usage**:
```
/refactor-google-style                # All C++ + Python files
/refactor-google-style src/           # Scope to a path
/refactor-google-style src/foo.cc     # Single file
/refactor-google-style --cpp-only
/refactor-google-style --python-only
/refactor-google-style --dry-run      # Report only, no writes
```

### Workflow

| Step | Action |
|------|--------|
| 1 | Scope discovery (glob C++/Python, exclude `.venv/`, `build/`, `dist/`, `third_party/`, `vendor/`) |
| 2 | Install/verify config (`.clang-format` from `templates/google-style/`, ruff section in `pyproject.toml`) |
| 3 | Mechanical pass — `clang-format -i`, `ruff check --fix --unsafe-fixes` + `ruff format` |
| 4 | Semantic pass — dispatch `google-style-refactor-cpp` / `google-style-refactor-python` agents in parallel (batches of ≤20) |
| 5 | Verify — re-run formatters, run project tests when discoverable |
| 6 | Per-language summary (files changed, top rule categories, human-review flags) |

Preconditions: clean worktree (or explicit confirmation), `ruff` installed for Python, `clang-format` on PATH for C++.

---

## /setup-pre-commit

Scaffold `.pre-commit-config.yaml` (+ `.clang-format` for C/C++ projects) in the current project. Variant auto-selected per `rules/pre-commit-policy.md`:

- `local-uv` — when `uv.lock` exists or `pyproject.toml` declares `[tool.uv]` / `[dependency-groups]`. Python hooks run via `uv run …` so `uv.lock` is the single source of truth.
- `external-mirrors` — otherwise. Python hooks pinned via `rev:` on mirror repos (`ruff-pre-commit`, `mirrors-mypy`, `pyright-python`).

**Usage**:
```
/setup-pre-commit
```

Steps:

1. Resolve plugin root and locate `templates/pre-commit/`.
2. Detect target project root (`git rev-parse --show-toplevel`).
3. Pick variant.
4. If `.pre-commit-config.yaml` already exists, diff against the variant and prompt before overwriting.
5. Copy variant to project root. Copy `.clang-format` if C/C++ sources detected.
6. Run `pre-commit install`, then `pre-commit run --all-files`.
7. Report variant, files written, first-run outcome.

Bumping tool versions is a marketplace-side change: edit `templates/pre-commit/variants/*.yaml`, push, `/plugin marketplace update claude-useful-instructions`, then re-run `/setup-pre-commit` per project.
