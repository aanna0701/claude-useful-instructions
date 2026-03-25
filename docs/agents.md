# Agents Reference

Agents are subagent definitions (`.md` files) under `.claude/agents/`. Claude Code delegates specific tasks to them based on the `description` field.

---

## Documentation Agents

Used by the `diataxis-doc-system` skill and `/write-doc` command.

### Diataxis Writers

| Agent | Type | Description |
|-------|------|-------------|
| `doc-writer-tutorial` | Tutorial | Step-by-step learning guides. Checkpoint pattern, golden path principle. |
| `doc-writer-howto` | How-to Guide | Problem-solving recipes. Flexible steps, prerequisite gates. |
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

## CI Audit Agent

Used by the `/gha-branch-sync` command. Audits GitHub Actions workflows against the project's branch-map configuration.

| Agent | Description |
|-------|-------------|
| `ci-audit-agent` | Scans `.github/workflows/` for hardcoded branch targets, missing freshness checks, missing path filters, and drift detection gaps. Reports issues and recommends minimal diffs. |

Reads `.claude/branch-map.yaml`, `.claude/rules/branch-map-policy.md`, and `.claude/rules/review-merge-policy.md` before analysis.

---

## VLA Project Agents

Domain-specific agents for the VLA (Vision-Language-Action) robotics project.

| Agent | Domain | Tools | Model |
|-------|--------|-------|-------|
| `vla-capture` | Camera capture, robot communication | Read, Write, Edit, Bash, Glob, Grep | sonnet |
| `vla-data` | Data pipeline, preprocessing, lerobot format | Read, Write, Edit, Bash, Glob, Grep | sonnet |
| `vla-model` | VLM backbone + Action decoder | Read, Write, Edit, Bash, Glob, Grep | sonnet |
| `vla-train` | QLoRA fine-tuning, Action BC training | Read, Write, Edit, Bash, Glob, Grep | sonnet |
| `vla-eval` | Performance metrics, safety_guard validation | Read, Write, Edit, Bash, Glob, Grep | sonnet |
| `vla-infra` | Docker, docker-compose, build/deploy scripts | Read, Write, Edit, Bash, Glob, Grep | sonnet |

### Naming Convention

Project prefix pattern: `<project>-<domain>.md` (e.g., `vla-capture.md`)

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
