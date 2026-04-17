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

## Collaboration Agents

Used by the `collab-workflow` skill and `/work-*` commands.

| Agent | Model | Effort | Role |
|-------|-------|--------|------|
| `pr-reviewer` | **opus** | **max** | Review PRs against work item contracts |

Revise loop is handled by re-running `/work-impl {ID}` or `/work-refactor`, which fetches unresolved PR review threads via GraphQL — no separate reviser agent. Cursor/Antigravity parity is maintained through per-bundle `.cursor/rules/*.mdc` files dropped at install time, not a runtime agent.

---

## Diagnostic Agents

Used by the `/debug-guide` and `/what-to-do` commands. Both analyze recent git commits without editing code.

| Agent | Model | Effort | Role |
|-------|-------|--------|------|
| `debug-guide` | sonnet | medium | Scan recent diffs, detect risk patterns (error handling, concurrency, config changes), output prioritized verification checklist |
| `what-to-do` | sonnet | medium | Summarize recent work and categorize next steps into Verify / Debug / Implement |

---

## Doc Polisher

| Agent | Model | Effort | Description |
|-------|-------|--------|-------------|
| `doc-polisher` | sonnet | medium | Applies writing-style and structural fixes directly to existing docs (counterpart to `doc-reviewer`, which only suggests). Invoked by `/polish-doc`. |

---

## PPT Generation Agents

Used by the `/generate-ppt` command and `ppt-generation` skill. Both run after content injection to enforce the template's design contract.

| Agent | Model | Effort | Role |
|-------|-------|--------|------|
| `ppt-density-checker` | sonnet | medium | Detect over-dense slides; flag slides violating density budgets |
| `ppt-format-reviewer` | sonnet | medium | Final compliance check for fonts, layout, colors, shapes against the base template |

---

## Google Style Refactor Agents

Used by the `/refactor-google-style` command and `google-style-refactor` skill. Dispatched in parallel on file batches after the mechanical formatter pass.

| Agent | Scope | Model | Effort |
|-------|-------|-------|--------|
| `google-style-refactor-cpp` | `*.{cpp,cc,cxx,h,hpp}` semantic rewrite (naming, includes, ownership, docstrings) | sonnet | medium |
| `google-style-refactor-python` | `*.py` semantic rewrite (docstrings, type hints, naming, import groups) | sonnet | medium |

Each agent reads `rules/google-style-{cpp,python}.md` before rewriting.

---

## CI Audit Agent

Used by the `/gha-branch-sync` command. Audits GitHub Actions workflows against the project's branch-map configuration.

| Agent | Model | Effort | Description |
|-------|-------|--------|-------------|
| `ci-audit-agent` | **opus** | **max** | Scans `.github/workflows/` for hardcoded branch targets, missing freshness checks, missing path filters, and drift detection gaps. Reports issues and recommends minimal diffs. |

Reads `.claude/branch-map.yaml` and `.claude/rules/review-merge-policy.md` before analysis.

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
| `low` | sonnet (or haiku) | Mechanical data movement, simple sync/format tasks | — |
| `medium` | sonnet | Standard code/doc generation, straightforward analysis, routine writing | `dl-*`, `debug-guide`, `what-to-do`, `diagram-writer`, `doc-polisher`, most `doc-writer-*`, `doc-reviewer-execution`, `ppt-density-checker`, `ppt-format-reviewer`, `google-style-refactor-cpp`, `google-style-refactor-python` |
| `medium` | opus | Medium tasks that still benefit from Opus quality (e.g. Korean career documents with strong tone requirements) | `career-docs-writer`, `career-docs-reviser` |
| `high` | sonnet | Senior sonnet judgment calls where opus isn't warranted (none currently) | — |
| `max` | **opus only** | Deep-judgment tasks: quality scoring, cross-system audits, final review gates, architectural decisions | `pr-reviewer`, `doc-reviewer`, `ci-audit-agent`, `career-docs-reviewer`, `doc-writer-explain` |

**Pipeline guideline**: early stages (scaffold / first-pass generation) use `medium` + sonnet; any deep-judgment / review-gate / audit stage uses `max` + opus. `high` without opus is reserved for the rare case where sonnet is preferred but the task still needs stretched reasoning.
