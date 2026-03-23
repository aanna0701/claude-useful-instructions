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
alias cui-codex-setup='bash $CUI_DIR/codex-setup.sh'
alias cui-gemini-setup='bash $CUI_DIR/gemini-setup.sh'
EOF
source ~/.bashrc

# zsh (~/.zshrc)
CUI_DIR=~/claude-useful-instructions  # ← adjust to your clone path
cat >> ~/.zshrc << EOF
alias cui-install='$CUI_DIR/install.sh'
alias cui-codex-setup='bash $CUI_DIR/codex-setup.sh'
alias cui-gemini-setup='bash $CUI_DIR/gemini-setup.sh'
EOF
source ~/.zshrc
```

**Setup example:**

```bash
# 1. Global — coding standards, doc tools
cui-install --core --docs

# 2. Per-project — collab workflow + Codex + Gemini
cui-install --collab /path/to/my-project
cui-codex-setup /path/to/my-project
cui-gemini-setup /path/to/my-project      # optional
```

### Gemini MCP Prerequisites

`cui-gemini-setup` requires a Gemini API key. Get one at https://aistudio.google.com/apikey.

The setup script will prompt for the key if `GEMINI_API_KEY` is not set, or you can pass it:

```bash
# Option A: Let the script prompt you
cui-gemini-setup /path/to/my-project

# Option B: Set it beforehand
export GEMINI_API_KEY="your-key-here"
cui-gemini-setup /path/to/my-project
```

The script uses `claude mcp add -s user` to register the server in `~/.claude.json` (user scope), which works across all projects and git worktrees.

> **Why `claude mcp add` instead of editing config files?**
> - `~/.claude/settings.json`'s `mcpServers` field is **not** where Claude Code reads MCP servers.
> - Per-project `settings.local.json` doesn't work with git worktrees.
> - Shell env vars (`.bashrc`/`.profile`) are unreliable for non-interactive MCP processes.
> - `claude mcp add -s user` writes to `~/.claude.json`, the correct location Claude Code reads.

After setup, **restart Claude Code** for the MCP server to connect.

---

## Bundles

| Bundle | Contents | Recommended Scope |
|--------|----------|-------------------|
| `core` | coding-style, smart-git-commit-push, optimize-tokens | Global (`~/.claude/`) |
| `docs` | diataxis-doc-system, diagram-architect, doc/diagram agents, write-doc, init-docs, sync-docs | Global |
| `data-pipeline` | data-pipeline-architect skill | Global |
| `collab` | Claude-Codex-Gemini collaboration, work items, AGENTS.md, CLAUDE.md, Gemini MCP | Per-project |
| `career` | career-docs skill, career agents | Either |
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
```

---

## Skills

Auto-triggered by Claude Code based on conversation context.

| Skill | Trigger Examples |
|-------|-----------------|
| `diataxis-doc-system` | "Write docs", "Design doc", "API docs" |
| `diagram-architect` | "Draw diagram", "System structure", "ERD" |
| `data-pipeline-architect` | "Design data pipeline", "ETL architecture" |
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
│   └── career-docs/                 # Cover letter & career documents (Korean)
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
├── mcp/gemini-review/               # Gemini MCP server
├── install.sh                       # Bundle-based installer
├── uninstall.sh                     # Clean uninstaller
├── codex-setup.sh                   # Codex-side setup
├── codex-implement.sh               # Codex entry point
└── gemini-setup.sh                  # Gemini MCP setup
```

---

## Detailed Guides

| Guide | Description |
|-------|-------------|
| [Collab Workflow](docs/collab-workflow.md) | Claude-Codex-Gemini architecture, setup, and walkthrough |
| [Skills Reference](docs/skills.md) | Full skill documentation |
| [Agents Reference](docs/agents.md) | Full agent documentation |
| [Commands Reference](docs/commands.md) | Full command documentation |

## Adding New Configuration

1. Add files to `skills/`, `agents/`, `commands/`, or `rules/`
2. `git commit && git push`
3. On other machines: `git pull && ./install.sh`
