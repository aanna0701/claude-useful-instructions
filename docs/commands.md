# Commands Reference

Commands are user-invocable slash commands (`.md` files) under `.claude/commands/`. Users type `/<command-name>` to trigger them.

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

Sync project documentation to the current codebase state. Detects outdated docs and updates them.

**Usage**:
```
/sync-docs              # Sync all changed .md files
/sync-docs README.md    # Sync specific file only
```

---

## /cover-letter

NotebookLM MCP-based Korean cover letter writing multi-agent system. Optimized for experienced hire applications.

**Usage**:
```
/cover-letter           # Start cover letter pipeline
```

### 3-Stage Pipeline

| Stage | Description | Session |
|-------|-------------|---------|
| 1 | Context extraction from NotebookLM | Chat A |
| 2 | Career description & essay generation | Chat A |
| 3 | Cover letter writing (Writer-Reviewer loop) | Chat B (new session recommended) |

### Writing Modes

| Mode | Description |
|------|-------------|
| A | Write from scratch |
| B | Improve user's own draft |
| C | Improve previously generated + user-edited draft |

### Evaluation Criteria (7 items, 0-100 scale)

| # | Item | Description |
|---|------|-------------|
| 1 | Grammar/Spelling | Spacing, particles, spelling |
| 2 | Naturalness & Expertise | Flow, professional tone |
| 3 | Fact Verification | Cross-check against Stage 1/2 docs |
| 4 | AI Style/Exaggeration | Detect AI-sounding phrases |
| 5 | Job Fit | JD matching, competency framing |
| 6 | Structure | Narrative arc, intro-conclusion coverage |
| 7 | Character Count | Within limits, space utilization |

### Exit Conditions

- **Normal**: Minimum 3 iterations AND all items >= 90 points
- **Plateau**: 3 consecutive iterations with no improvement → submit best-scoring draft

### Prerequisites

```bash
uv tool install notebooklm-mcp-cli   # Install
nlm login                             # Google login
nlm setup add cursor                  # Register MCP in Cursor
nlm doctor                            # Diagnose
```

Upload resume/portfolio to the "Cover Letter" notebook in NotebookLM before starting.

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

## /smart-git-commit-push

Analyze changes, auto-split by feature into separate commits, and push.

**Usage**:
```
/smart-git-commit-push              # Commit + push to current branch
/smart-git-commit-push main         # Push to main branch
```
