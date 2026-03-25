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
| `core` | smart-git-commit-push, optimize-tokens, branch-map | Global (`~/.claude/`) |
| `docs` | diataxis-doc-system, diagram-architect, doc/diagram agents, write-doc, init-docs, sync-docs | Global |
| `data-pipeline` | data-pipeline-architect skill | Global |
| `collab` | Claude-Codex collaboration, work items, CI audit, AGENTS.md, CLAUDE.md | Per-project |
| `slack` | Slack notifications (session summary, confirmation alerts) | Global |
| `career` | career-docs skill, career agents | Either |
| `presentation` | html-presentation skill, create/format/edit/export-pdf commands | Global |
| `vla` | vla-code-standards, vla agents (6 domains) | Either |

> **Global** (`~/.claude/`): language-agnostic tools usable everywhere.
> **Per-project** (`project/.claude/`): CLAUDE.md, AGENTS.md, work items, MCP are project-specific.

### Slack Setup

The `slack` bundle requires a Bot Token and Channel ID.

**1. Create a Slack App**

1. Go to [api.slack.com/apps](https://api.slack.com/apps) → **Create New App** → **From scratch**
2. Name it (e.g., `Claude Code Notifier`), select your workspace

**2. Configure Bot Permissions**

1. **OAuth & Permissions** → **Bot Token Scopes** → Add:
   - `chat:write` — send messages
   - `chat:write.public` — post to channels without joining
2. **Install to Workspace** → Authorize

**3. Copy the Bot Token**

After install, copy the **Bot User OAuth Token** (`xoxb-...`) from **OAuth & Permissions**.

**4. Get the Channel ID**

1. Open Slack → right-click the target channel → **View channel details**
2. Scroll to the bottom — copy the **Channel ID** (`C...`)

**5. Configure**

```bash
# Option A: Interactive install (prompts for token & channel)
./install.sh --interactive --slack

# Option B: Manual — edit the config file after install
./install.sh --slack
vim ~/.claude/hooks/slack_config.json
```

```json
{
  "bot_token": "xoxb-your-token-here",
  "channel_id": "C0123456789"
}
```

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
| `career-docs` | "자소서 써줘", "Cover letter", "경력기술서" |
| `collab-workflow` | "Work item", "Codex", "Hand off", "Delegate" |

> Full reference: [docs/skills.md](docs/skills.md)

## Agents

Subagents delegated by Claude for specific tasks.

| Group | Agents | Count |
|-------|--------|-------|
| Documentation | `doc-writer-tutorial`, `-howto`, `-explain`, `-reference` | 4 |
| Delivery | `doc-writer-task`, `-contract`, `-checklist`, `-review` | 4 |
| Doc Quality | `doc-polisher`, `doc-reviewer`, `doc-reviewer-execution` | 3 |
| Diagram | `diagram-writer` | 1 |
| Token Analysis | `token-duplication-detector`, `-load-measurer`, `-mcp-analyzer`, `-split-detector` | 4 |
| Career Docs | `career-docs-writer`, `-reviewer`, `-reviser` | 3 |
| CI Audit | `ci-audit-agent` | 1 |
| VLA Project | `vla-capture`, `-data`, `-model`, `-train`, `-eval`, `-infra` | 6 |

> Full reference: [docs/agents.md](docs/agents.md)

## Commands

| Command | Description |
|---------|-------------|
| `/branch-init` | Detect/configure branch hierarchy for the project |
| `/branch-status` | Show branch map, freshness, and work item mapping |
| `/work-plan` | Create work item for Codex delegation |
| `/work-status` | Check work item progress |
| `/work-review` | Review Codex implementation against contract |
| `/gha-branch-sync` | Audit GitHub Actions against branch map |
| `/write-doc` | Diataxis-based document writing |
| `/polish-doc` | Apply writing-style and structural fixes to existing docs |
| `/init-docs` | Scaffold docs site structure (numbering + MkDocs) |
| `/sync-docs` | Sync docs to current codebase state |
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
| `branch-map-policy.md` | Branch hierarchy selection, safety rules, worktree routing |
| `collab-workflow.md` | Claude-Codex role separation, work item protocol |
| `review-merge-policy.md` | Merge gating: freshness, CI checks, MUST-fix resolution |
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
│   ├── doc-polisher.md              # Doc writing-style polish
│   ├── doc-reviewer.md              # Diataxis doc quality review
│   ├── doc-reviewer-execution.md    # Execution artifact review
│   ├── token-*.md                   # Token optimization analysis (4 agents)
│   ├── ci-audit-agent.md             # GitHub Actions topology audit
│   ├── career-docs-*.md             # Career document writer & reviewer
│   └── vla-*.md                     # VLA robotics project (6 domains)
├── commands/                        # User-invocable slash commands
├── rules/                           # Shared code standards
├── templates/                       # Installable templates
│   ├── branch-map/                  # branch-map.yaml bootstrap config
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
