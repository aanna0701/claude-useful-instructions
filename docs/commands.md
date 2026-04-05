# Commands Reference

Commands are user-invocable slash commands (`.md` files) under `.claude/commands/`. Users type `/<command-name>` to trigger them.

---

## /branch-init

Detect or configure the branch hierarchy for the current project. Persists the result in `.claude/branch-map.yaml`.

**Usage**:
```
/branch-init              # Auto-detect from existing branches
/branch-init develop      # Set develop as working parent
/branch-init research     # Set research as working parent
```

### Workflow

| Step | Action |
|------|--------|
| 1 | Check for existing `.claude/branch-map.yaml` |
| 2 | Detect integration branches (main, develop, research, etc.) |
| 3 | Build trunk chain and set working parent |
| 4 | Confirm with user |
| 5 | Write `.claude/branch-map.yaml` |
| 6 | Auto-audit GHA workflows if `.github/workflows/` exists |

Works standalone (single agent) or with the collab workflow. Part of the **core** bundle.

---

## /branch-status

Show current branch hierarchy, freshness state, and work item branch mappings.

**Usage**:
```
/branch-status            # Full status
/branch-status --brief    # One-line summary
```

### Output

- Trunk chain and working parent
- Current branch freshness vs parent (ahead/behind)
- Work item branch mappings (if collab workflow active)

---

## /gha-branch-sync

Audit GitHub Actions workflows against the project's branch map configuration.

**Usage**:
```
/gha-branch-sync              # Audit only (report issues)
/gha-branch-sync --fix        # Audit + apply fixes after confirmation
/gha-branch-sync --generate   # Generate missing workflows from branch-map roles
```

### Checks

| Check | What It Detects |
|-------|----------------|
| Hardcoded targets | Merge/deploy targeting a fixed branch instead of branch-map |
| Missing freshness | No parent branch comparison before merge gates |
| Missing path filters | All-path triggers causing unnecessary CI runs |
| Drift detection | Docs/contract changes not notifying affected PRs |
| Stale references | Branch names that no longer exist in trunk chain |

Delegates analysis to the `ci-audit-agent` subagent.

---

## /work-plan

Create a work item for delegation (Codex or branch-based). Generates brief, contract, checklist, and optionally a GitHub Issue.

**Usage**:
```
/work-plan <description>
```

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

Implement a work item in a worktree.

**Usage**:
```
/work-impl #123           # By GitHub Issue number
/work-impl FEAT-001       # By work item ID
```

---

## /work-revise

Re-dispatch a work item that failed review with targeted fix instructions.

**Usage**:
```
/work-revise FEAT-001
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

Sync project documentation to the current codebase state. Detects outdated docs and updates them.

**Usage**:
```
/sync-docs              # Sync all changed .md files
/sync-docs README.md    # Sync specific file only
```

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

## /smart-git-commit-push

Analyze changes, auto-split by feature into separate commits, and push.

**Usage**:
```
/smart-git-commit-push              # Commit + push to current branch
/smart-git-commit-push main         # Push to main branch
```

---

## /create-presentation

Generate a new HTML slide deck from content (text or file). Free-form design with 16:9 ratio and keyboard navigation.

**Usage**:
```
/create-presentation [file_path or text]
```

### Workflow

| Step | Action |
|------|--------|
| 1 | Content analysis (topic, flow, audience) |
| 2 | Slide structure design (6-12 slides, one message per slide) |
| 3 | HTML generation (16:9, dark/light, keyboard nav) |
| 4 | Save as `{topic}-presentation.html` |

### Layout Selection

| Content Pattern | Layout |
|----------------|--------|
| 3-way comparison | 3-column cards |
| Sequential steps | Arrow flow / timeline |
| Key numbers | Large stat blocks |
| Lists | Icon cards |
| Tabular data | Styled table (zebra stripe) |

> Upgrade to standard format: `/format-presentation topic-presentation.html logo.png`

---

## /format-presentation

Convert an existing HTML presentation to the standard 16:9 dark-theme slide deck format using `base-template.html`.

**Usage**:
```
/format-presentation [input.html] [logo_path]
```

### Workflow

| Step | Action |
|------|--------|
| 1 | Read input HTML + validate logo path |
| 2 | Execute `html-presentation` skill (Phase 0-4) |
| 3 | Save as `{original}-formatted.html` with slide summary |

Content is preserved as-is; only CSS/JS/layout is replaced with the standard template.

> Export to PDF: `/export-pdf {filename}`

---

## /edit-presentation

Modify content in a formatted HTML presentation. CSS/JS/template structure is never touched.

**Usage**:
```
/edit-presentation [input.html] [instructions]
```

### Absolute Rules

1. CSS `<style>` block — never modify
2. `<script>` block — never modify
3. `.slide-header` / `.slide-nav` structure — never modify
4. Unmentioned slides — never touch
5. Class names, `data-slide` numbers, `.slide-label` — never change

### Workflow

| Step | Action |
|------|--------|
| 1 | Read file, verify standard format |
| 2 | Parse instructions into change table (slide / target / before / after) |
| 3 | Apply edits via Edit tool (text only, preserve HTML tags) |
| 4 | Verify: CSS/JS unchanged, `data-slide` continuity, `.slide-label` consistency |

---

## /export-pdf

Convert an HTML slide deck to PDF. Captures only the 16:9 slide area at 1920×1080 (no letterbox).

**Usage**:
```
/export-pdf [input.html] [output.pdf]    # output defaults to {input}.pdf
```

### Prerequisites

```bash
uv run playwright install chromium
```

Requires `playwright` and `pillow` (auto-installed via `pyproject.toml`).
