# claude-useful-instructions

Portable Claude Code configuration. One `./install.sh` to apply everywhere.

## Installation

```bash
git clone https://github.com/aanna0701/claude-useful-instructions.git
cd claude-useful-instructions
```

### Quick Alias (optional)

```bash
# Add to ~/.bashrc or ~/.zshrc for quick access
echo "alias cui-install='~/workspace/claude-useful-instructions/install.sh'" >> ~/.bashrc
source ~/.bashrc
```

Then use `cui-install` anywhere instead of the full path:

```bash
cui-install --core --docs
cui-install --collab /path/to/project
```

### Recommended Usage

```bash
# 1. Global — coding standards, doc tools (shared across all projects)
./install.sh --core --docs

# 2. Per-project — collaboration workflow (project-specific)
./install.sh --collab /path/to/my-project
bash codex-setup.sh /path/to/my-project      # Codex side
bash gemini-setup.sh /path/to/my-project     # Gemini MCP (optional)
```

| Scope | Bundles | Why |
|-------|---------|-----|
| **Global** (`~/.claude/`) | `core`, `docs`, `data-pipeline` | Language-agnostic tools usable everywhere |
| **Per-project** (`project/.claude/`) | `collab` | CLAUDE.md, AGENTS.md, work items, MCP are project-specific |
| **Either** | `career`, `vla` | Depends on whether one project or many need them |

> `collab` installs CLAUDE.md, AGENTS.md, and scripts at the project root — these define per-project contracts, boundaries, and work items that are specific to each codebase.

### All Options

```bash
./install.sh                                        # All bundles → ~/.claude/
./install.sh /path/to/project                       # All bundles → project
./install.sh --list                                 # Show available bundles
./install.sh --core --docs                          # Specific bundles only
./install.sh --exclude career --exclude vla         # All except specific bundles
./install.sh --interactive                          # Interactive menu
```

| Bundle | Contents |
|--------|----------|
| `core` | coding-style, smart-git-commit-push, optimize-tokens |
| `docs` | diataxis-doc-system, diagram-architect, doc/diagram agents, write-doc, init-docs, sync-docs |
| `data-pipeline` | data-pipeline-architect skill |
| `career` | career-docs skill, career agents |
| `vla` | vla-code-standards, vla agents (6 domains) |
| `collab` | Claude-Codex-Gemini collaboration, work items, AGENTS.md, CLAUDE.md, Gemini MCP |

---

## Claude-Codex-Gemini Collaboration

The `collab` bundle enables structured handoff between **Claude** (design/review), **Codex** (implementation), and **Gemini** (audit/synthesis via MCP).

### Roles

| Agent | Role | Writes |
|-------|------|--------|
| **Claude** | spec owner, integrator, final authority | brief, contract (signed), review.md |
| **Codex** | implementer farm | code, status.md |
| **Gemini** | auditor, synthesizer, spec normalizer | review-gemini.md, contract (draft) |

### Architecture

```mermaid
graph LR
    subgraph "1 Claude — Design"
        A["/work-plan"] --> G1["Gemini MCP\nsummarize + derive"]
        G1 --> B["brief.md\ncontract.md\nchecklist.md"]
        A -.->|no Gemini| B
    end

    subgraph "Shared Workspace"
        B --> C["work/items/\nFEAT-NNN-slug/"]
    end

    subgraph "2 Codex — Implement"
        C --> D["codex-implement.sh\nFEAT-NNN"]
        D --> E["code +\nstatus.md"]
    end

    subgraph "3 Review"
        E --> G2["Gemini MCP\naudit"]
        G2 --> F["Claude\n/work-review"]
        E -.->|no Gemini| F
        F --> H["review.md\nMERGE / REVISE / REJECT"]
    end

    H -.->|REVISE| D
```

### Setup

#### Step 1: Install collab bundle

```bash
./install.sh --collab /path/to/project
```

This copies all Claude-side artifacts (rules, commands, skills, templates) to `.claude/`, places `AGENTS.md`, `CLAUDE.md`, scripts, and the Gemini MCP server at the project root.

#### Step 2: Set up Codex

```bash
bash codex-setup.sh /path/to/project
```

Places `AGENTS.md` + `codex-implement.sh` at project root. Creates `work/items/` directory. Run this once per project.

#### Step 3: Set up Gemini MCP (optional)

```bash
# 1. Get a Gemini API key
#    → https://aistudio.google.com/apikey

# 2. Set environment variable
export GEMINI_API_KEY='your-api-key-here'

# 3. Run setup (installs deps, prints config)
bash gemini-setup.sh /path/to/project
```

The setup script prints a JSON snippet to add to Claude Code settings. Add it to either:
- **Project-level**: `/path/to/project/.claude/settings.local.json`
- **Global**: `~/.claude/settings.json`

```json
{
  "mcpServers": {
    "gemini-review": {
      "command": "uv",
      "args": ["run", "--directory", "/path/to/project/mcp/gemini-review", "python", "server.py"],
      "env": { "GEMINI_API_KEY": "${GEMINI_API_KEY}" }
    }
  },
  "permissions": {
    "allow": [
      "mcp__gemini_review__gemini_summarize_design_pack",
      "mcp__gemini_review__gemini_derive_contract",
      "mcp__gemini_review__gemini_audit_implementation",
      "mcp__gemini_review__gemini_compare_diffs",
      "mcp__gemini_review__gemini_draft_release_notes"
    ]
  }
}
```

Override the model with `GEMINI_MODEL` (default: `gemini-2.5-pro`):
```bash
export GEMINI_MODEL='gemini-2.5-flash'  # cheaper, faster
```

#### Installed Layout

```
project/
├── AGENTS.md                          # Codex reads this
├── CLAUDE.md                          # Claude reads this
├── codex-implement.sh                 # Codex entry point
├── codex-setup.sh                     # Codex setup script
├── gemini-setup.sh                    # Gemini MCP setup script
├── mcp/gemini-review/                 # Gemini MCP server
│   ├── server.py                      #   5 tools wrapping Gemini API
│   ├── prompts.py                     #   System prompts per tool
│   └── pyproject.toml                 #   Dependencies (mcp, google-generativeai)
├── work/items/                        # Shared workspace (created by codex-setup.sh)
└── .claude/
    ├── rules/collab-workflow.md       # Auto-loaded 3-agent rules
    ├── commands/work-{plan,review,status}.md
    ├── skills/collab-workflow/
    └── templates/work-item/*.md       # Brief, contract, checklist, status, review, review-gemini
```

### Gemini MCP Tools

| Tool | Insertion Point | Purpose |
|------|----------------|---------|
| `gemini_summarize_design_pack` | Before /work-plan | Compress RFC/ADR bundle into implementation-ready summary |
| `gemini_derive_contract` | During /work-plan | Generate contract.md draft from design summary |
| `gemini_audit_implementation` | Before /work-review | Neutral third-party compliance audit |
| `gemini_compare_diffs` | Before integration | Cross-compare parallel branch diffs |
| `gemini_draft_release_notes` | After merge | Generate release notes with migration steps |

### Workflow Example

> Scenario: "Add JWT authentication middleware"

#### Phase 1 — Design (Claude + Gemini)

```
[Claude] /work-plan "Add JWT authentication middleware"
```

Claude gathers RFC/ADR, optionally calls Gemini to summarize and derive contract draft:

```
Gemini: summarize_design_pack(["docs/rfc/RFC-012.md", "docs/adr/ADR-005.md"])
  → Implementation-ready summary (valid decisions, invariants, open questions)

Gemini: derive_contract(summary, scope, boundaries)
  → contract.md draft (status: draft)

Claude: reviews + signs contract (status: draft → signed)

Created work/items/FEAT-001-jwt-auth-middleware/
  brief.md       — objective, scope, dependencies
  contract.md    — interfaces, allowed/forbidden files, invariants (signed by Claude)
  checklist.md   — 5 verification items (Yes/No)
  status.md      — status: open

Codex Command:
  bash codex-implement.sh FEAT-001
```

#### Phase 2 — Implement (Codex)

```
[Codex] bash codex-implement.sh FEAT-001
```

The script auto-reads brief, contract, checklist and initializes status:

```mermaid
sequenceDiagram
    participant U as User
    participant X as Codex
    participant W as work/items/FEAT-001/

    U->>X: bash codex-implement.sh FEAT-001
    X->>W: Read brief.md → contract.md → checklist.md
    X->>W: Update status.md (in-progress, Agent: Codex)
    X->>X: git checkout -b feat/FEAT-001-jwt-auth-middleware

    loop For each contract requirement
        X->>X: Implement + write tests
        X->>W: Update status.md (progress, changed files)
        X->>X: git commit -m "feat(FEAT-001): ..."
    end

    X->>W: Update status.md (done)
```

Codex implements strictly within contract boundaries:

```
[Codex] Reading contract... Allowed: src/middleware/, tests/middleware/
[Codex] Reading contract... Forbidden: src/database/
[Codex] feat(FEAT-001): add JWT validation middleware
[Codex] feat(FEAT-001): add middleware unit tests
[Codex] Updated status.md → done (5/5 checklist items)
```

#### Phase 3 — Monitor (Claude)

```
[Claude] /work-status FEAT-001

FEAT-001: JWT Auth Middleware
Status:     done
Agent:      Codex
Branch:     feat/FEAT-001-jwt-auth-middleware
Progress:   5/5 checklist items
```

#### Phase 4 — Review (Gemini + Claude)

```
[Claude] /work-review FEAT-001
```

Gemini audits first (neutral third-party), then Claude makes the final decision:

```
Gemini: audit_implementation(contract, changed_files, checklist)
  → review-gemini.md:
    Contract Compliance: 5/5 Pass
    Boundary Violations: None
    Edge Cases: Token expiry race condition (LOW)
    Written: work/items/FEAT-001-jwt-auth-middleware/review-gemini.md

Claude (informed by Gemini audit):
  Contract Compliance: 5/5 Pass
  Additional finding: Token expiry race condition noted, acceptable for v1

Decision: MERGE
Written: work/items/FEAT-001-jwt-auth-middleware/review.md
```

#### Phase 5 — Merge or Revise

```mermaid
flowchart TD
    R{"/work-review\nDecision"}
    M["git merge\nfeat/FEAT-001-*"]
    V["Generate revision\nprompt for Codex"]
    X["Close work item\nwith reason"]
    C["Codex fixes\nrevision items"]

    R -->|MERGE| M
    R -->|REVISE| V
    R -->|REJECT| X
    V --> C
    C --> R
```

If **REVISE**, Claude outputs specific fix items and a new Codex prompt. Codex addresses them and the review cycle repeats.

### Work Item Files

| File | Author | Purpose |
|------|--------|---------|
| `brief.md` | Claude | Objective, scope, dependencies |
| `contract.md` | Gemini (draft) → Claude (signed) | Interfaces, boundaries, invariants, test requirements |
| `checklist.md` | Claude | Yes/No verification items |
| `status.md` | Codex | Real-time progress, blockers, ambiguities, changed files |
| `review-gemini.md` | Gemini | Neutral compliance audit (pre-review) |
| `review.md` | Claude | Final review, deviations, lessons, merge decision |

### Commands & Tools

| Command/Tool | Actor | Description |
|-------------|-------|-------------|
| `/work-plan [topic]` | Claude | Create work item bundle for Codex delegation |
| `/work-status [FEAT-NNN]` | Claude | Check progress (summary table or detail view) |
| `/work-review [FEAT-NNN]` | Claude | Review implementation against contract |
| `bash codex-implement.sh FEAT-NNN` | Codex | Load work item and start implementing |
| `gemini_summarize_design_pack` | Gemini (MCP) | Compress design docs into summary |
| `gemini_derive_contract` | Gemini (MCP) | Generate contract draft |
| `gemini_audit_implementation` | Gemini (MCP) | Neutral pre-review audit |
| `gemini_compare_diffs` | Gemini (MCP) | Cross-compare parallel branches |
| `gemini_draft_release_notes` | Gemini (MCP) | Generate release notes |

---

## Structure

```
claude-useful-instructions/
├── skills/                          # Auto-triggered by conversation context
│   ├── diataxis-doc-system/         # Diátaxis documentation system
│   ├── diagram-architect/           # C4 Mermaid architecture diagrams
│   ├── data-pipeline-architect/     # Data pipeline design + subagent generation
│   ├── collab-workflow/             # Claude-Codex collaboration workflow
│   └── career-docs/                 # Cover letter & career documents (Korean)
├── agents/                          # Subagents delegated by Claude
│   ├── doc-writer-*.md              # Diátaxis doc writers (4 types + delivery agents)
│   ├── diagram-writer.md            # Mermaid diagram generation
│   ├── career-docs-*.md             # Career document writer & reviewer
│   └── vla-*.md                     # VLA robotics project (6 domains)
├── commands/                        # User-invocable slash commands
│   ├── work-plan.md                 # /work-plan — create work item for Codex
│   ├── work-review.md               # /work-review — review Codex implementation
│   ├── work-status.md               # /work-status — check work item progress
│   ├── write-doc.md                 # /write-doc
│   ├── init-docs.md                 # /init-docs
│   ├── sync-docs.md                 # /sync-docs
│   ├── optimize-tokens.md           # /optimize-tokens
│   └── smart-git-commit-push.md     # /smart-git-commit-push
├── rules/                           # Shared code standards
│   ├── coding-style.md              # English-only, immutability, file size
│   ├── collab-workflow.md           # Claude-Codex role separation, work item rules
│   └── vla-code-standards.md        # pydantic vs dataclass, TDD, imports
├── templates/                       # Installable templates
│   ├── work-item/                   # brief, contract, checklist, status, review, review-gemini
│   ├── codex/AGENTS.md              # Codex instruction file
│   └── claude/CLAUDE.md             # Claude project instruction file
├── mcp/gemini-review/               # Gemini MCP server
│   ├── server.py                    # 5 tools wrapping Gemini API
│   ├── prompts.py                   # System prompts per tool
│   └── pyproject.toml               # Dependencies
├── install.sh                       # Bundle-based installer
├── uninstall.sh                     # Clean uninstaller
├── codex-setup.sh                   # Codex-side setup (AGENTS.md + codex-implement.sh)
├── codex-implement.sh               # Codex entry point (reads work item, initializes status)
└── gemini-setup.sh                  # Gemini MCP setup (install deps + print config)
```

---

## Skills

Auto-triggered by Claude Code based on conversation context. → [Full reference](docs/skills.md)

| Skill | Trigger Examples |
|-------|-----------------|
| `diataxis-doc-system` | "Write docs", "Design doc", "API docs" |
| `diagram-architect` | "Draw diagram", "System structure", "ERD" |
| `data-pipeline-architect` | "Design data pipeline", "ETL architecture" |
| `collab-workflow` | "Work item", "Codex", "Hand off", "Delegate" |

## Agents

Subagents delegated by Claude for specific tasks. → [Full reference](docs/agents.md)

| Group | Agents | Count |
|-------|--------|-------|
| Documentation | `doc-writer-tutorial`, `-howto`, `-explain`, `-reference` | 4 |
| Delivery | `doc-writer-task`, `-contract`, `-checklist`, `-review` | 4 |
| Diagram | `diagram-writer` | 1 |
| Cover Letter | `cover-letter-writer`, `-reviewer` | 2 |
| VLA Project | `vla-capture`, `-data`, `-model`, `-train`, `-eval`, `-infra` | 6 |

## Commands

User-invocable slash commands. → [Full reference](docs/commands.md)

| Command | Description |
|---------|-------------|
| `/work-plan` | Create work item for Codex delegation |
| `/work-status` | Check work item progress |
| `/work-review` | Review Codex implementation against contract |
| `/write-doc` | Diátaxis-based document writing |
| `/init-docs` | Scaffold docs site structure (numbering + MkDocs) |
| `/sync-docs` | Sync docs to current codebase state |
| `/cover-letter` | Multi-agent cover letter pipeline (Korean) |
| `/smart-git-commit-push` | Auto-split commits by feature and push |
| `/optimize-tokens` | Analyze and reduce token waste in instructions |

## Rules

Shared code standards installed to `.claude/rules/`.

| File | Content |
|------|---------|
| `coding-style.md` | English-only, immutability, file size limits, error handling |
| `collab-workflow.md` | Claude-Codex role separation, work item protocol |
| `vla-code-standards.md` | pydantic vs dataclass, frozen patterns, TDD, import order |

> Subagents do NOT auto-read rules. Agent definitions must include explicit Read instructions.

---

## Adding New Configuration

1. Add files to `skills/`, `agents/`, `commands/`, or `rules/`
2. `git commit && git push`
3. On other machines: `git pull && ./install.sh`
