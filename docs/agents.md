# Agents Reference

Agents are subagent definitions (`.md` files) under `.claude/agents/`. Claude Code delegates specific tasks to them based on the `description` field.

---

## Documentation Agents

Used by the `diataxis-doc-system` skill and `/write-doc` command.

| Agent | Type | Description |
|-------|------|-------------|
| `doc-writer-tutorial` | Tutorial | Step-by-step learning guides. Checkpoint pattern, golden path principle. |
| `doc-writer-howto` | How-to Guide | Problem-solving recipes. Flexible steps, prerequisite gates. |
| `doc-writer-explain` | Explanation | Design Docs (RFC) and ADRs. 4+1 View Model, alternatives comparison required. |
| `doc-writer-reference` | Reference | API/Config/CLI specs. Tables first, consistent structure, code-synced. |

### How They're Invoked

```
/write-doc or diataxis-doc-system skill
  → Phase 1: Classify document type
  → Phase 2: Delegate to matching doc-writer-* agent
  → Phase 3: Quality review
```

---

## Diagram Agent

| Agent | Description |
|-------|-------------|
| `diagram-writer` | Generates Mermaid code following diagram-rules. Invoked by `diagram-architect` skill in Phase 3. |

---

## Cover Letter Agents

Used by the `/cover-letter` command. Korean cover letter writing system optimized for experienced hires.

| Agent | Role |
|-------|------|
| `cover-letter-writer` | Generates cover letter drafts using NotebookLM context |
| `cover-letter-reviewer` | Reviews drafts on 7 criteria (0-100 scale), provides improvement feedback |

### Writer-Reviewer Loop

- Minimum 3 iterations
- Exit: all criteria >= 90 points, OR 3 consecutive iterations with no improvement (use best score draft)

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
