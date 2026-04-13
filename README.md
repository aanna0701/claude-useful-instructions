# claude-useful-instructions

Portable Claude Code configuration. One `./install.sh` to apply everywhere.

## Quick Start

```bash
git clone https://github.com/aanna0701/claude-useful-instructions.git
cd claude-useful-instructions

# Global — coding standards, doc tools (shared across all projects)
./install.sh --core --docs

# Per-project — collaboration workflow (project-specific)
./install.sh --collab /path/to/my-project
```

### Aliases (optional)

Replace `<CUI_DIR>` with your clone path (e.g., `~/claude-useful-instructions`).

```bash
# bash (~/.bashrc)
CUI_DIR=~/claude-useful-instructions  # ← adjust to your clone path
cat >> ~/.bashrc << EOF
alias cui-install='$CUI_DIR/install.sh'

EOF
source ~/.bashrc

# zsh (~/.zshrc)
CUI_DIR=~/claude-useful-instructions  # ← adjust to your clone path
cat >> ~/.zshrc << EOF
alias cui-install='$CUI_DIR/install.sh'
EOF
source ~/.zshrc
```

**Setup example:**

```bash
# 1. Global — coding standards, doc tools
cui-install --core --docs

# 2. Per-project — collab workflow
cui-install --collab /path/to/my-project
```

---

## Bundles

| Bundle | Contents | Recommended Scope |
|--------|----------|-------------------|
| `core` | smart-git-commit-push, optimize-tokens, debug-guide, what-to-do, token analyzers, **hooks** (git-auto-pull, guard-branch, branch-naming, auto-pr-commit, worktree-cleanup, auto-pr), pre-commit templates | Global (`~/.claude/`) |
| `docs` | diataxis-doc-system, diagram-architect, doc/diagram agents, write-doc, init-docs, sync-docs | Global |
| `data-pipeline` | data-pipeline-architect skill | Global |
| `collab` | Claude-Codex collaboration, work items, AI IDE integration (pipeline rule for Cursor/Antigravity, scaffold/verify), CI audit, codex-run, AGENTS.md, CLAUDE.md | Per-project |
| `career` | career-docs skill, career agents | Either |
| `presentation` | html-presentation skill, create/format/edit/export-pdf commands | Global |
| `worknote` | Work journal with Notion sync (daily log, review, planning) | Global |
| `ppt-generation` | PPT template-based generation (fill content into base PPT without changing design) | Global |
| `dl` | pytorch-dl-standards + dl agents (capture, data, model, train, eval, infra) | Either |

> **Global** (`~/.claude/`): language-agnostic tools usable everywhere.
> **Per-project** (`project/.claude/`): CLAUDE.md, AGENTS.md, work items, MCP are project-specific.

## Git Workflow (Hook-Enforced)

The `core` bundle installs hooks that enforce a strict worktree-based git workflow:

```
Code edit on main repo
  → guard-branch blocks it
  → creates worktree (feature-*) + GitHub Issue
  → redirects edit to worktree

First git commit in worktree
  → auto-pr-commit pushes branch
  → creates draft PR (Closes #issue)

PR merged
  → worktree-cleanup deletes:
    - worktree directory
    - local branch
    - remote branch
```

### Branch Naming Convention

All branches must follow `feature-*` pattern:

| Type | Branch Pattern | Example |
|------|---------------|---------|
| feat | `feature-{slug}` | `feature-user-auth` |
| fix | `feature-fix-{slug}` | `feature-fix-login-crash` |
| refactor | `feature-refac-{slug}` | `feature-refac-db-schema` |
| docs | `feature-docs-{slug}` | `feature-docs-api-guide` |
| perf | `feature-perf-{slug}` | `feature-perf-query-cache` |
| adhoc | `feature-adhoc-{MMDD-HHMM}` | `feature-adhoc-0408-1530` |

### Hooks Summary

| Hook | Event | What It Does |
|------|-------|-------------|
| `branch-naming` | PreToolUse (Bash) | Blocks non-`feature-*` branch names |
| `guard-branch` | PreToolUse (Edit/Write) | Redirects code edits to worktree + creates Issue |
| `auto-pr-commit` | PostToolUse (Bash) | Draft PR on first `git commit` |
| `worktree-cleanup` | PostToolUse (Bash) + Stop | Deletes merged worktrees + remote branches |
| `auto-pr` | Stop | Fallback PR creation if hook missed |
| `git-auto-pull` | PreToolUse (Edit/Write) | Auto `git pull` once per session |

### Pre-commit (Code Quality)

The `core` bundle installs `.pre-commit-config.yaml` with:

| Language | Formatting | Lint | Type Check |
|----------|-----------|------|-----------|
| Python | ruff-format | ruff | pyright, mypy |
| C++ | clang-format | — | — |

### Prerequisites

#### Notion MCP (optional — for `worknote` bundle)

The `worknote` skill uses Notion as a work journal backend via MCP.

1. Create a Notion Integration at https://www.notion.so/profile/integrations
   - Name: `claude-journal` (or any name)
   - Capabilities: **Read**, **Update**, **Insert** content
   - Copy the **Internal Integration Secret** (`ntn_...`)

2. Add MCP server (global scope — available in all projects):
   ```bash
   claude mcp add --scope user notion \
     -e NOTION_TOKEN=ntn_YOUR_TOKEN \
     -- npx @notionhq/notion-mcp-server
   ```

3. Set up Notion workspace:
   - Create a page (e.g., "업무일지") to hold the journal database
   - Open that page → **⋯ → Connections → Add your integration**
   - The `worknote` skill will create a "Daily Worknote" inline DB inside this page
   - Update the DB ID in `skills/worknote/references/notion-schema.md`

4. Verify:
   ```bash
   claude mcp list
   # notion: npx @notionhq/notion-mcp-server - ✓ Connected
   ```

> **Note**: This is separate from any Notion SDK usage in your application code.
> MCP is for Claude Code to interact with Notion during conversations.

#### GitHub CLI (`gh`)

The `collab` bundle requires **GitHub CLI (`gh`)** for full functionality:

| Feature | Requires `gh` | Without `gh` |
|---------|:---:|---|
| Worktree creation | No | Works fine |
| Work item generation | No | Works fine |
| GitHub Issue creation (`/work-plan` Step 7) | **Yes** | Silently skipped, `issue` stays `null` in dispatch.json |
| `/gha-branch-sync` CI audit | **Yes** | Cannot run |

```bash
# Install gh CLI
# Ubuntu/Debian
sudo apt install gh

# macOS
brew install gh

# Conda
conda install gh --channel conda-forge

# Then authenticate
gh auth login
```

### Install Options

```bash
./install.sh                                        # All bundles → ~/.claude/
./install.sh /path/to/project                       # All bundles → project
./install.sh --list                                 # Show available bundles
./install.sh --core --docs                          # Specific bundles only
./install.sh --exclude career --exclude dl           # All except specific bundles
./install.sh --interactive                          # Interactive menu

# Uninstall
./install.sh --uninstall /path/to/project           # Remove all installed files
./install.sh --uninstall --collab /path/to/project   # Remove collab bundle only
```

---

## Skills

Auto-triggered by Claude Code based on conversation context.

| Skill | Trigger Examples |
|-------|-----------------|
| `diataxis-doc-system` | "Write docs", "Design doc", "API docs" |
| `diagram-architect` | "Draw diagram", "System structure", "ERD" |
| `data-pipeline-architect` | "Design data pipeline", "ETL architecture" |
| `html-presentation` | "PPT format", "Slide conversion", "format-presentation" |
| `career-docs` | "자소서 써줘", "Cover letter", "경력기술서" |
| `collab-workflow` | "Work item", "Codex", "Hand off", "Delegate", "scaffold", "verify", "audit" |
| `ppt-generation` | "템플릿에 내용 넣어줘", "베이스 PPT에 채워줘", "fill template", ".potx" |
| `worknote` | "업무일지", "업무 기록", "오늘 뭐했", "work note" |

> Full reference: [docs/skills.md](docs/skills.md)

## Agents

Subagents delegated by Claude for specific tasks.

| Group | Agents | Count |
|-------|--------|-------|
| Documentation | `doc-writer-guide`, `-explain`, `-reference` | 3 |
| Delivery | `doc-writer-task`, `-contract`, `-checklist`, `-review` | 4 |
| Doc Quality | `doc-polisher`, `doc-reviewer`, `doc-reviewer-execution` | 3 |
| Diagram | `diagram-writer` | 1 |
| Debug / Planning | `debug-guide`, `what-to-do` | 2 |
| Work Journal | `worknote-sync`, `-review`, `-plan` | 3 |
| Token Analysis | `token-duplication-detector`, `-load-measurer`, `-mcp-analyzer`, `-split-detector` | 4 |
| Career Docs | `career-docs-writer`, `-reviewer`, `-reviser` | 3 |
| Collab Workflow | `pr-reviewer`, `work-reviser`, `cursor-prompt-builder` | 3 |
| CI Audit | `ci-audit-agent` | 1 |
| PPT Generation | `ppt-density-checker`, `ppt-format-reviewer` | 2 |
| DL Pipeline | `dl-capture`, `-data`, `-model`, `-train`, `-eval`, `-infra` | 6 |

> Full reference: [docs/agents.md](docs/agents.md)

## Commands

| Command | Description |
|---------|-------------|
| `/work-plan` | Create work item for Codex delegation |
| `/work-status` | Check work item progress |
| `/work-impl` | Implement a work item in its worktree per contract |
| `/work-review` | Review Codex implementation against contract |
| `/work-scaffold` | Generate Cursor/Antigravity Composer prompts + .cursor/rules/*.mdc from contracts |
| `/work-verify` | Codebase audit via Cursor/Antigravity (AUDIT type only, `--ingest` for result parsing) |
| `/work-revise` | Re-dispatch REVISE items from review to agent or Codex |
| `/gha-branch-sync` | Audit GitHub Actions against branch map |
| `/write-doc` | Diataxis-based document writing |
| `/polish-doc` | Apply writing-style and structural fixes to existing docs |
| `/init-docs` | Scaffold docs site structure (numbering + MkDocs) |
| `/sync-docs` | Sync docs to current codebase state |
| `/debug-guide` | Analyze recent commits and generate a verification/debug checklist |
| `/what-to-do` | Review recent commits and generate an action plan (verify, debug, implement) |
| `/smart-git-commit-push` | Auto-split commits by feature and push |
| `/create-presentation` | Generate HTML slide deck from content |
| `/format-presentation` | Convert HTML to standard 16:9 dark-theme format |
| `/edit-presentation` | Modify content in formatted presentations |
| `/export-pdf` | Convert HTML slides to PDF (1920×1080) |
| `/generate-ppt` | Fill a base PPT template with source material content |
| `/optimize-tokens` | Analyze and reduce token waste in instructions |

> Full reference: [docs/commands.md](docs/commands.md)

## Rules

Shared code standards installed to `.claude/rules/`.

| File | Bundle | Content |
|------|--------|---------|
| `collab-workflow.md` | collab | Claude-Codex role separation, hook-enforced workflow, work item protocol |
| `review-merge-policy.md` | collab | Merge gating: freshness, CI checks, MUST-fix resolution |
| `pytorch-dl-standards.md` | dl | PyTorch DL standards: config/DTO, frozen patterns, kornia, tech stack |

> Subagents do NOT auto-read rules. Agent definitions must include explicit Read instructions.

---

## Project Structure

```
claude-useful-instructions/
├── skills/                          # Auto-triggered by conversation context
│   ├── diataxis-doc-system/         # Diataxis documentation system
│   ├── diagram-architect/           # C4 Mermaid architecture diagrams
│   ├── data-pipeline-architect/     # Data pipeline design + subagent generation
│   ├── collab-workflow/             # Claude-Codex collaboration workflow
│   ├── html-presentation/           # 16:9 dark-theme slide deck formatter + PDF export
│   ├── career-docs/                 # Cover letter & career documents (Korean)
│   ├── ppt-generation/              # PPT template-based content injection
│   └── worknote/                    # Work journal with Notion sync
├── agents/                          # Subagents delegated by Claude
│   ├── doc-writer-*.md              # Diataxis doc writers (4 types + delivery agents)
│   ├── diagram-writer.md            # Mermaid diagram generation
│   ├── debug-guide.md               # Commit analysis → verification checklist
│   ├── what-to-do.md                # Recent work summary → action plan
│   ├── doc-polisher.md              # Doc writing-style polish
│   ├── doc-reviewer.md              # Diataxis doc quality review
│   ├── doc-reviewer-execution.md    # Execution artifact review
│   ├── token-*.md                   # Token optimization analysis (4 agents)
│   ├── worknote-*.md                # Work journal agents (sync, review, plan)
│   ├── ppt-density-checker.md       # Slide density QA
│   ├── ppt-format-reviewer.md       # Template format compliance review
│   ├── pr-reviewer.md               # PR review against work item contract
│   ├── work-reviser.md              # Re-dispatch REVISE items from review
│   ├── cursor-prompt-builder.md     # Contract → Cursor/Antigravity prompts
│   ├── ci-audit-agent.md            # GitHub Actions topology audit
│   ├── career-docs-*.md             # Career document writer & reviewer
│   └── dl-*.md                      # DL pipeline agents (6 domains)
├── commands/                        # User-invocable slash commands
├── rules/                           # Shared code standards
├── docs/                            # Detailed reference guides
│   ├── collab-workflow.md           # Claude-Codex architecture & walkthrough
│   ├── skills.md                    # Full skill documentation
│   ├── agents.md                    # Full agent documentation
│   └── commands.md                  # Full command documentation
├── scripts/                         # Standalone utility scripts
│   ├── html_to_pdf.py               # Playwright-based HTML→PDF slide converter
│   └── patch-hook-settings.py       # Hook settings patcher for installer
├── lib/                             # Codex runner modules (sourced by codex-run.sh)
│   ├── codex-run-work.sh            # Work item dispatch logic
│   ├── codex-run-git.sh             # Git/worktree operations
│   ├── codex-run-boundary.sh        # Boundary check (changed-files audit)
│   └── codex-run-runner.sh          # Codex execution with stall detection
├── templates/                       # Installable templates
│   ├── pre-commit/                  # .pre-commit-config.yaml, .clang-format templates
│   ├── work-item/                   # brief, contract, checklist, status, review, relay
│   ├── collab-pipeline-body.md      # Single source for `/collab-workflow` pipeline (assembled by install.sh)
│   ├── cursor/                      # Cursor/Antigravity prompt templates + per-item .mdc patterns
│   ├── workflows/                   # GitHub Actions workflow templates
│   ├── codex/AGENTS.md
│   └── claude/CLAUDE.md
├── hooks/                           # Claude Code hooks
│   ├── lib/                         # Shared utilities (gh_utils, worktree_state)
│   ├── git-auto-pull/               # Pre-edit auto-pull hook
│   ├── branch-naming/               # Enforce feature-* branch naming
│   ├── guard-branch/                # Redirect code edits to worktree + auto-create Issue
│   ├── auto-pr-commit/              # Draft PR on first commit
│   ├── worktree-cleanup/            # Delete merged worktrees + remote branches
│   ├── auto-pr/                     # Fallback PR creation on session end
│   └── worknote-stop/               # Session-end work journal capture
├── install.sh                       # Bundle-based installer (+ --uninstall)
└── codex-run.sh                     # Codex runner (single + parallel + boundary check)
```

---

## Detailed Guides

| Guide | Description |
|-------|-------------|
| [Collab Workflow](docs/collab-workflow.md) | Claude-Codex architecture, setup, and walkthrough |
| [Cursor/Antigravity Integration](docs/cursor-integration.md) | IDE AI as pipeline orchestrator, structure propagator, and codebase verifier |
| [Skills Reference](docs/skills.md) | Full skill documentation |
| [Agents Reference](docs/agents.md) | Full agent documentation |
| [Commands Reference](docs/commands.md) | Full command documentation |

## Adding New Configuration

1. Add files to `skills/`, `agents/`, `commands/`, or `rules/`
2. `git commit && git push`
3. On other machines: `git pull && ./install.sh`
