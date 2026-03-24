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
| `core` | coding-style, smart-git-commit-push, optimize-tokens | Global (`~/.claude/`) |
| `docs` | diataxis-doc-system, diagram-architect, doc/diagram agents, write-doc, init-docs, sync-docs | Global |
| `data-pipeline` | data-pipeline-architect skill | Global |
| `collab` | Claude-Codex collaboration, work items, AGENTS.md, CLAUDE.md | Per-project |
| `slack` | Slack notifications (session summary, confirmation alerts) | Global |
| `career` | career-docs skill, career agents | Either |
| `presentation` | html-presentation skill, create/format/edit/export-pdf commands | Global |
| `vla` | vla-code-standards, vla agents (6 domains) | Either |

> **Global** (`~/.claude/`): language-agnostic tools usable everywhere.
> **Per-project** (`project/.claude/`): CLAUDE.md, AGENTS.md, work items, MCP are project-specific.

### Install Options

```bash
./install.sh                                        # All bundles → ~/.claude/
./install.sh /path/to/project                       # All bundles → project
./install.sh --list                                 # Show available bundles
./install.sh --core --docs                          # Specific bundles only
./install.sh --exclude career --exclude vla         # All except specific bundles
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
| `collab-workflow` | "Work item", "Codex", "Hand off", "Delegate" |

> Full reference: [docs/skills.md](docs/skills.md)

## Agents

Subagents delegated by Claude for specific tasks.

| Group | Agents | Count |
|-------|--------|-------|
| Documentation | `doc-writer-tutorial`, `-howto`, `-explain`, `-reference` | 4 |
| Delivery | `doc-writer-task`, `-contract`, `-checklist`, `-review` | 4 |
| Diagram | `diagram-writer` | 1 |
| Cover Letter | `cover-letter-writer`, `-reviewer` | 2 |
| VLA Project | `vla-capture`, `-data`, `-model`, `-train`, `-eval`, `-infra` | 6 |

> Full reference: [docs/agents.md](docs/agents.md)

## Commands

| Command | Description |
|---------|-------------|
| `/work-plan` | Create work item for Codex delegation |
| `/work-status` | Check work item progress |
| `/work-review` | Review Codex implementation against contract |
| `/write-doc` | Diataxis-based document writing |
| `/init-docs` | Scaffold docs site structure (numbering + MkDocs) |
| `/sync-docs` | Sync docs to current codebase state |
| `/cover-letter` | Multi-agent cover letter pipeline (Korean) |
| `/smart-git-commit-push` | Auto-split commits by feature and push |
| `/create-presentation` | Generate HTML slide deck from content |
| `/format-presentation` | Convert HTML to standard 16:9 dark-theme format |
| `/edit-presentation` | Modify content in formatted presentations |
| `/export-pdf` | Convert HTML slides to PDF (1920×1080) |
| `/optimize-tokens` | Analyze and reduce token waste in instructions |

> Full reference: [docs/commands.md](docs/commands.md)

## Rules

Shared code standards installed to `.claude/rules/`.

| File | Content |
|------|---------|
| `coding-style.md` | English-only, immutability, file size limits, error handling |
| `collab-workflow.md` | Claude-Codex role separation, work item protocol |
| `vla-code-standards.md` | pydantic vs dataclass, frozen patterns, TDD, import order |

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
│   └── career-docs/                 # Cover letter & career documents (Korean)
├── scripts/                         # Standalone utility scripts
│   └── html_to_pdf.py               # Playwright-based HTML→PDF slide converter
├── agents/                          # Subagents delegated by Claude
│   ├── doc-writer-*.md              # Diataxis doc writers (4 types + delivery agents)
│   ├── diagram-writer.md            # Mermaid diagram generation
│   ├── career-docs-*.md             # Career document writer & reviewer
│   └── vla-*.md                     # VLA robotics project (6 domains)
├── commands/                        # User-invocable slash commands
├── rules/                           # Shared code standards
├── templates/                       # Installable templates
│   ├── work-item/                   # brief, contract, checklist, status, review
│   ├── codex/AGENTS.md
│   └── claude/CLAUDE.md
├── hooks/                           # Claude Code hooks
│   └── slack/                       # Slack notification hooks (buffer, stop, notify)
├── install.sh                       # Bundle-based installer (+ --uninstall)
├── codex-run.sh                     # Codex runner (single + parallel + boundary check)
└── link-work.sh                     # Worktree symlink manager
```

---

## Detailed Guides

| Guide | Description |
|-------|-------------|
| [Collab Workflow](docs/collab-workflow.md) | Claude-Codex architecture, setup, and walkthrough |
| [Skills Reference](docs/skills.md) | Full skill documentation |
| [Agents Reference](docs/agents.md) | Full agent documentation |
| [Commands Reference](docs/commands.md) | Full command documentation |

## Adding New Configuration

1. Add files to `skills/`, `agents/`, `commands/`, or `rules/`
2. `git commit && git push`
3. On other machines: `git pull && ./install.sh`
