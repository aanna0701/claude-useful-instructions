# Agents Reference

Agents are subagent definitions (`.md` files) under `.claude/agents/`. Claude Code delegates specific tasks to them based on the `description` field.

---

## Documentation Agents

Used by the `diataxis-doc-system` skill and `/write-doc` command.

### Diataxis Writers

| Agent | Type | Model | Effort | Description |
|-------|------|-------|--------|-------------|
| `doc-writer-guide` | Guide | sonnet | medium | Step-by-step procedures (beginner or practitioner level). Checkpoint pattern, workflow organization, DRY linking. |
| `doc-writer-explain` | Explanation | **opus** | **max** | Design Docs (RFC) and ADRs. 4+1 View Model, alternatives comparison required. |
| `doc-writer-reference` | Reference | sonnet | medium | API/Config/CLI specs. Tables first, consistent structure, code-synced. |

### Delivery Writers

| Agent | Type | Model | Effort | Description |
|-------|------|-------|--------|-------------|
| `doc-writer-task` | Task/Brief | sonnet | medium | Work orders (standalone) or work item briefs (bundle). Objective, source, scope. |
| `doc-writer-contract` | Contract | sonnet | medium | Implementation boundaries, interfaces, invariants. Allowed/forbidden zones. |
| `doc-writer-checklist` | Checklist | sonnet | medium | Verification checklists. All items Yes/No verifiable. Links to parent. |
| `doc-writer-review` | Review | sonnet | medium | Post-completion assessment. Contract compliance, lessons, merge decision. |

### Reviewers

| Agent | Scope | Model | Effort | Description |
|-------|-------|-------|--------|-------------|
| `doc-reviewer` | `docs/` | **opus** | **max** | Reviews Diataxis docs for readability, type purity, writing style, and governance. Scores A-D. |
| `doc-reviewer-execution` | `work/` | sonnet | medium | Reviews execution artifacts for structural integrity, contract compliance, and completeness. Scores A-D. |

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

| Agent | Model | Effort | Description |
|-------|-------|--------|-------------|
| `diagram-writer` | sonnet | medium | Generates Mermaid code following diagram-rules. Invoked by `diagram-architect` skill in Phase 3. |

---

## Career Docs Agents

Used by the `career-docs` skill. Korean career document generation & refinement through a 3-stage pipeline.

| Agent | Model | Effort | Role |
|-------|-------|--------|------|
| `career-docs-writer` | **opus** | medium | 6-step checklist refinement of NLM draft |
| `career-docs-reviewer` | **opus** | **max** | 6-dimension scoring (0-100) + specific fix instructions |
| `career-docs-reviser` | **opus** | medium | Apply Reviewer fixes in single pass (score <90 only) |

### 3-Stage Pipeline

Writer → Reviewer → Reviser (if any dimension < 90)

---

## Token Analysis Agents

Used by the `/optimize-tokens` command. Invoked inline (no standalone frontmatter), so they inherit model + effort from the calling session.

| Agent | Role |
|-------|------|
| `token-duplication-detector` | Cross-file duplication analysis (command↔agent, reference↔agent, intra-file) |
| `token-mcp-analyzer` | MCP call efficiency mapping and redundancy detection |
| `token-load-measurer` | Per-session token load tracing and bloat detection |
| `token-split-detector` | Identifies files that should be split into focused units |

---

## Work Journal Agents

Used by the `worknote` skill. Daily work journal management with Notion sync. Declared as `subagent_type: general-purpose`, so model inherits from the session.

| Agent | Model | Effort | Role |
|-------|-------|--------|------|
| `worknote-sync` | inherit | low | Push local `~/.claude/worknote/*.md` to Notion DB (one page per project per day) |
| `worknote-review` | inherit | medium | Query Notion by date range, generate 3-section narrative summary per project |
| `worknote-plan` | inherit | medium | Generate prioritized work plan from recent entries + git state |

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

| Agent | Model | Effort | Role |
|-------|-------|--------|------|
| `pr-reviewer` | **opus** | **max** | Review PRs against work item contracts |
| `work-reviser` | sonnet | medium | Re-dispatch failed review items with targeted fixes |
| `cursor-prompt-builder` | sonnet | medium | Parse contracts, detect type from ID prefix, assemble Cursor/Antigravity prompts + rules |

### cursor-prompt-builder

Invoked by `/work-scaffold` and `/work-verify`. Handles the full pipeline:

1. Detects work item type from ID prefix (FEAT → `scaffold-feat.md`, REFAC → `scaffold-refactor.md`, AUDIT → `verify-audit.md`)
2. Parses `brief.md` and `contract.md` into structured data
3. Selects the type-specific template from `.claude/templates/cursor/`
4. Fills template variables and returns the rendered prompt
5. For scaffold mode: derives glob patterns from contract paths and generates `.cursor/rules/{SLUG}-guard.mdc` (contract boundary enforcement) and `{SLUG}-forbidden.mdc` (forbidden zone warning)

---

## CI Audit Agent

Used by the `/gha-branch-sync` command. Audits GitHub Actions workflows against the project's branch-map configuration.

| Agent | Model | Effort | Description |
|-------|-------|--------|-------------|
| `ci-audit-agent` | **opus** | **max** | Scans `.github/workflows/` for hardcoded branch targets, missing freshness checks, missing path filters, and drift detection gaps. Reports issues and recommends minimal diffs. |

Reads `.claude/branch-map.yaml`, `.claude/rules/branch-map-policy.md`, and `.claude/rules/review-merge-policy.md` before analysis.

---

## VLA Project Agents

PyTorch DL pipeline agents covering the full lifecycle from data acquisition to evaluation.

| Agent | Domain | Model | Effort |
|-------|--------|-------|--------|
| `dl-capture` | Data acquisition, sensor/camera capture | sonnet | medium |
| `dl-data` | Data pipeline, preprocessing, dataset conversion | sonnet | medium |
| `dl-model` | Model architecture, backbone + head/decoder | sonnet | medium |
| `dl-train` | Training pipeline, fine-tuning, distributed training | sonnet | medium |
| `dl-eval` | Evaluation metrics, validation, benchmarks | sonnet | medium |
| `dl-infra` | Docker, docker-compose, build/deploy scripts | sonnet | medium |

All `dl-*` agents use `Read, Write, Edit, Bash, Glob, Grep` tools.

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
effort: medium # low | medium | high | max (max = Opus only)
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
- **`model`**: `haiku` for trivial tasks (3× cheaper), `sonnet` for standard work, `opus` for deep-judgment agents. Pair `opus` with `effort: max`.
- **`effort`**: overrides the session's reasoning effort while the subagent is active. See the Effort + Model Policy table below.
- Project agents: `<project>/.claude/agents/`, global agents: `~/.claude/agents/`
- Agents do NOT auto-read `CLAUDE.md` or `.claude/rules/` — include explicit Read instructions in the agent definition

### Effort + Model Policy

Reasoning effort should match the agent's responsibility, and model should match the reasoning depth. Pair `high` effort with `opus` whenever deep judgment is needed.

| Effort | Default model | When to use | Agents in this repo |
|--------|---------------|-------------|---------------------|
| `low` | sonnet (or haiku) | Mechanical data movement, simple sync/format tasks | `worknote-sync` |
| `medium` | sonnet | Standard code/doc generation, straightforward analysis, routine writing | `dl-*`, `debug-guide`, `what-to-do`, `diagram-writer`, `doc-polisher`, most `doc-writer-*`, `doc-reviewer-execution`, `ppt-*`, `worknote-plan`, `worknote-review` |
| `medium` | opus | Medium tasks that still benefit from Opus quality (e.g. Korean career documents with strong tone requirements) | `career-docs-writer`, `career-docs-reviser` |
| `high` | sonnet | Senior sonnet judgment calls where opus isn't warranted (none currently) | — |
| `max` | **opus only** | Deep-judgment tasks: quality scoring, cross-system audits, final review gates, architectural decisions | `pr-reviewer`, `doc-reviewer`, `ci-audit-agent`, `career-docs-reviewer`, `doc-writer-explain` |

**Pipeline guideline**: early stages (scaffold / first-pass generation) use `medium` + sonnet; any deep-judgment / review-gate / audit stage uses `max` + opus. `high` without opus is reserved for the rare case where sonnet is preferred but the task still needs stretched reasoning.

**Pipeline guideline**: early stages (scaffold / first-pass generation) use `medium`; final review or merge-gating stages use `high` (or `max` on Opus for the hardest cases).
