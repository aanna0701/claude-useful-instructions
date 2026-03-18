# claude-useful-instructions

Portable Claude Code configuration. One `./install.sh` to apply everywhere.

## Installation

```bash
git clone https://github.com/aanna0701/claude-useful-instructions.git
cd claude-useful-instructions
./install.sh                        # Global: ~/.claude/
./install.sh /path/to/project       # Project-specific: /path/to/project/.claude/
```

---

## Structure

```
claude-useful-instructions/
├── skills/                          # Auto-triggered by conversation context
│   ├── diataxis-doc-system/         # Diátaxis documentation system
│   ├── diagram-architect/           # C4 Mermaid architecture diagrams
│   ├── diagram-pipeline/            # mermaid → draw.io → docs pipeline
│   └── data-pipeline-architect/     # Data pipeline design + subagent generation
├── agents/                          # Subagents delegated by Claude
│   ├── doc-writer-*.md              # Diátaxis doc writers (4 types)
│   ├── diagram-writer.md            # Mermaid diagram generation
│   ├── cover-letter-*.md            # Cover letter writer & reviewer
│   └── vla-*.md                     # VLA robotics project (6 domains)
├── commands/                        # User-invocable slash commands
│   ├── write-doc.md                 # /write-doc
│   ├── init-docs.md                 # /init-docs
│   ├── sync-docs.md                 # /sync-docs
│   ├── cover-letter.md              # /cover-letter
│   └── smart-git-commit-push.md     # /smart-git-commit-push
├── rules/                           # Shared code standards
│   ├── coding-style.md              # English-only, immutability, file size
│   └── vla-code-standards.md        # pydantic vs dataclass, TDD, imports
├── install.sh
└── uninstall.sh
```

---

## Skills

Auto-triggered by Claude Code based on conversation context. → [Full reference](docs/skills.md)

| Skill | Trigger Examples |
|-------|-----------------|
| `diataxis-doc-system` | "Write docs", "Design doc", "API docs" |
| `diagram-architect` | "Draw diagram", "System structure", "ERD" |
| `diagram-pipeline` | "Convert mermaid to drawio", "Embed diagrams" |
| `data-pipeline-architect` | "Design data pipeline", "ETL architecture" |

## Agents

Subagents delegated by Claude for specific tasks. → [Full reference](docs/agents.md)

| Group | Agents | Count |
|-------|--------|-------|
| Documentation | `doc-writer-tutorial`, `-howto`, `-explain`, `-reference` | 4 |
| Diagram | `diagram-writer` | 1 |
| Cover Letter | `cover-letter-writer`, `-reviewer` | 2 |
| VLA Project | `vla-capture`, `-data`, `-model`, `-train`, `-eval`, `-infra` | 6 |

## Commands

User-invocable slash commands. → [Full reference](docs/commands.md)

| Command | Description |
|---------|-------------|
| `/write-doc` | Diátaxis-based document writing |
| `/init-docs` | Scaffold docs site structure (numbering + MkDocs) |
| `/sync-docs` | Sync docs to current codebase state |
| `/cover-letter` | Multi-agent cover letter pipeline (Korean) |
| `/smart-git-commit-push` | Auto-split commits by feature and push |

## Rules

Shared code standards installed to `.claude/rules/`.

| File | Content |
|------|---------|
| `coding-style.md` | English-only, immutability, file size limits, error handling |
| `vla-code-standards.md` | pydantic vs dataclass, frozen patterns, TDD, import order |

> Subagents do NOT auto-read rules. Agent definitions must include explicit Read instructions.

---

## Adding New Configuration

1. Add files to `skills/`, `agents/`, `commands/`, or `rules/`
2. `git commit && git push`
3. On other machines: `git pull && ./install.sh`
