# Agents Reference

Agents are subagent definitions (`.md` files) under `.claude/agents/`. Claude Code delegates specific tasks to them based on the `description` field.

---

## Documentation Agents

Used by the `diataxis-doc-system` skill and `/write-doc` command.

### Diataxis Writers

| Agent | Type | Description |
|-------|------|-------------|
| `doc-writer-guide` | Guide | Step-by-step procedures (beginner or practitioner level). Checkpoint pattern, workflow organization, DRY linking. |
| `doc-writer-explain` | Explanation | Design Docs (RFC) and ADRs. 4+1 View Model, alternatives comparison required. |
| `doc-writer-reference` | Reference | API/Config/CLI specs. Tables first, consistent structure, code-synced. |

### Delivery Writers

| Agent | Type | Description |
|-------|------|-------------|
| `doc-writer-task` | Task/Brief | Work orders (standalone) or work item briefs (bundle). Objective, source, scope. |
| `doc-writer-contract` | Contract | Implementation boundaries, interfaces, invariants. Allowed/forbidden zones. |
| `doc-writer-checklist` | Checklist | Verification checklists. All items Yes/No verifiable. Links to parent. |
| `doc-writer-review` | Review | Post-completion assessment. Contract compliance, lessons, merge decision. |

### Reviewers

| Agent | Scope | Description |
|-------|-------|-------------|
| `doc-reviewer` | `docs/` | Reviews Diataxis docs for readability, type purity, writing style, and governance. Scores A-D. |
| `doc-reviewer-execution` | `work/` | Reviews execution artifacts for structural integrity, contract compliance, and completeness. Scores A-D. |

### How They're Invoked

```
/write-doc or diataxis-doc-system skill
  → Phase 0.5: Axis determination (Diataxis or Delivery?)
  → Phase 1/1-D: Classify type/subtype
  → Phase 2: Delegate to matching doc-writer-* agent
  → Phase 3: Quality review
      docs/ → doc-reviewer
      work/ → doc-reviewer-execution
```

---

## Diagram Agent

| Agent | Description |
|-------|-------------|
| `diagram-writer` | Generates Mermaid code following diagram-rules. Invoked by `diagram-architect` skill in Phase 3. |

---

## Career Docs Agents

Used by the `career-docs` skill. Korean career document generation & refinement through a 3-stage pipeline.

| Agent | Role |
|-------|------|
| `career-docs-writer` | 6-step checklist refinement of NLM draft |
| `career-docs-reviewer` | 6-dimension scoring (0-100) + specific fix instructions |
| `career-docs-reviser` | Apply Reviewer fixes in single pass (score <90 only) |

### 3-Stage Pipeline

Writer → Reviewer → Reviser (if any dimension < 90)

---

## Token Analysis Agents

Used by the `/optimize-tokens` command. Parallel analysis agents for instruction token optimization.

| Agent | Role |
|-------|------|
| `token-duplication-detector` | Cross-file duplication analysis (command↔agent, reference↔agent, intra-file) |
| `token-mcp-analyzer` | MCP call efficiency mapping and redundancy detection |
| `token-load-measurer` | Per-session token load tracing and bloat detection |
| `token-split-detector` | Identifies files that should be split into focused units |

---

## Work Journal Agents

Used by the `worknote` skill. Daily work journal management with Notion sync.

| Agent | Role |
|-------|------|
| `worknote-sync` | Push local `~/.claude/worknote/*.md` to Notion DB (one page per project per day) |
| `worknote-review` | Query Notion by date range, generate 3-section narrative summary per project |
| `worknote-plan` | Generate prioritized work plan from recent entries + git state |

### Data Flow

```
Stop hook → local md → worknote-sync → Notion DB
                                         ↓
                        worknote-review ← query by period
                        worknote-plan  ← query + git branches
```

---

## Collaboration Agents

Used by the `collab-workflow` skill and `/work-*` commands.

| Agent | Role |
|-------|------|
| `issue-creator` | Create GitHub Issues from work item briefs |
| `pr-reviewer` | Review PRs against work item contracts |
| `work-reviser` | Re-dispatch failed review items with targeted fixes |
| `cursor-prompt-builder` | Parse contracts, detect type from ID prefix, assemble Cursor prompts + .cursor/rules/ |

### cursor-prompt-builder

Invoked by `/work-scaffold` and `/work-verify`. Handles the full pipeline:

1. Detects work item type from ID prefix (FEAT → `scaffold-feat.md`, REFAC → `scaffold-refactor.md`, AUDIT → `verify-audit.md`)
2. Parses `brief.md` and `contract.md` into structured data
3. Selects the type-specific template from `.claude/templates/cursor/`
4. Fills template variables and returns the rendered prompt
5. For scaffold mode: generates `.cursorrules` (legacy root-level)
6. For scaffold mode: derives glob patterns from contract paths and generates `.cursor/rules/{SLUG}-guard.mdc` (contract boundary enforcement) and `{SLUG}-forbidden.mdc` (forbidden zone warning)

---

## CI Audit Agent

Used by the `/gha-branch-sync` command. Audits GitHub Actions workflows against the project's branch-map configuration.

| Agent | Description |
|-------|-------------|
| `ci-audit-agent` | Scans `.github/workflows/` for hardcoded branch targets, missing freshness checks, missing path filters, and drift detection gaps. Reports issues and recommends minimal diffs. |

Reads `.claude/branch-map.yaml`, `.claude/rules/branch-map-policy.md`, and `.claude/rules/review-merge-policy.md` before analysis.

---

## VLA Project Agents

PyTorch DL pipeline agents covering the full lifecycle from data acquisition to evaluation.

| Agent | Domain | Tools | Model |
|-------|--------|-------|-------|
| `dl-capture` | Data acquisition, sensor/camera capture | Read, Write, Edit, Bash, Glob, Grep | sonnet |
| `dl-data` | Data pipeline, preprocessing, dataset conversion | Read, Write, Edit, Bash, Glob, Grep | sonnet |
| `dl-model` | Model architecture, backbone + head/decoder | Read, Write, Edit, Bash, Glob, Grep | sonnet |
| `dl-train` | Training pipeline, fine-tuning, distributed training | Read, Write, Edit, Bash, Glob, Grep | sonnet |
| `dl-eval` | Evaluation metrics, validation, benchmarks | Read, Write, Edit, Bash, Glob, Grep | sonnet |
| `dl-infra` | Docker, docker-compose, build/deploy scripts | Read, Write, Edit, Bash, Glob, Grep | sonnet |

### Naming Convention

Domain prefix pattern: `dl-<domain>.md` (e.g., `dl-capture.md`)

---

## Creating an Agent

```yaml
---
name: agent-name
description: "What this agent handles — Claude uses this to decide delegation"
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet  # sonnet | opus | haiku
---

# Agent Name

## Scope
- `src/module/` — description of owned area

## Rules
- Rule 1
- Rule 2
```

### Key Points

- **`description`** is the most important field — it determines when Claude delegates
- **`tools`**: Restrict to what the agent actually needs
- **`model`**: `haiku` for simple tasks (3x cheaper), `opus` for deep reasoning
- Project agents: `<project>/.claude/agents/`, global agents: `~/.claude/agents/`
- Agents do NOT auto-read `CLAUDE.md` or `.claude/rules/` — include explicit Read instructions in the agent definition
