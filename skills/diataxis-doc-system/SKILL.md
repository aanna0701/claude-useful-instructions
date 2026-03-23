---
name: diataxis-doc-system
description: >
  Diátaxis Framework + Work Item documentation system.
  Two axes: (1) Diátaxis — Tutorial, How-to, Explanation, Reference,
  (2) Delivery — Work Item Bundle (brief/contract/checklist/status/review) + standalone Task/Contract/Checklist/Review.
  Delegates to type-specific sub-agents.
  Triggers on: "write doc", "technical doc", "architecture doc", "API doc",
  "guide", "tutorial", "design doc", "RFC", "ADR", "README",
  "documentation", "technical writing", "how-to guide",
  "reference doc", "config reference", "CLI reference",
  "doc structure", "docs init", "MkDocs", "doc site",
  "information architecture",
  "work item", "task", "contract", "checklist", "review",
  "work order", "execution artifact", "multi-agent", "codex",
  "delivery document", "interface contract", "verification checklist".
  Consult this skill first for any documentation-related request.
---

# Diátaxis + Work Item Documentation System

Analyze request → **axis determination** → type routing → agent delegation → quality validation.

```
[Request] → Phase 0.5: Axis → Phase 1/1-D: Type → Phase 2: Agent → Phase 3: Quality
             (Diátaxis or Delivery?)  (select type)      (agents)       (rule check)
```

---

## Core Principle

Most documentation failures stem from **mixing different purposes in one document**.
This skill separates docs into **two axes** and delegates to specialized agents.

### Diátaxis Axis (reader-oriented — informational docs)

| Type | Purpose | Reader State | Agent |
|------|---------|-------------|-------|
| **Tutorial** | Learning | First encounter | `doc-writer-tutorial` |
| **How-to Guide** | Problem solving | Knows basics, has specific problem | `doc-writer-howto` |
| **Explanation** | Understanding | Wants to know "why" | `doc-writer-explain` |
| **Reference** | Information lookup | Needs exact specs | `doc-writer-reference` |

### Delivery Axis (execution-oriented — action docs)

| Type | Purpose | When Used | Agent |
|------|---------|-----------|-------|
| **Work Item** | Multi-agent coordination | Feature requiring Claude↔Codex handoff | bundle (5 agents) |
| **Task** | Standalone work assignment | Simple work derived from RFC/ADR | `doc-writer-task` |
| **Contract** | Interface agreement | Cross-module/team alignment | `doc-writer-contract` |
| **Checklist** | Completion verification | Task acceptance | `doc-writer-checklist` |
| **Review** | Result assessment | Post-task completion | `doc-writer-review` |

**Work Item Bundle** = `brief.md` + `contract.md` + `checklist.md` + `status.md` + `review.md` co-located in `work/items/FEAT-NNN-slug/`. Primary pattern for multi-agent workflows.

---

## Workflow

### Phase 0: Input Gathering

**Required (ask if missing):**
- Document topic/scope
- Target audience (newcomer? peer developer? management?) or task assignee
- Purpose (onboarding? design review? API release? work assignment? interface contract?)

**Optional (improves quality):**
- Existing codebase or docs
- Project glossary
- Existing diagrams
- Source RFC/ADR or Contract (for execution docs)

### Phase 0.5: Axis Determination

| Question | Yes → Axis |
|----------|-----------|
| Is the doc meant for understanding, learning, or lookup? | **Diátaxis** → Phase 1 |
| Is the doc meant for work assignment, interface agreement, verification, or assessment? | **Delivery** → Phase 1-D |

**Keyword shortcuts:**
- `work item`, `work-item`, `feature item` → Delivery (Work Item Bundle)
- `task`, `work order` → Delivery (Task)
- `contract`, `interface agreement` → Delivery (Contract)
- `checklist`, `verification list` → Delivery (Checklist)
- `review`, `assessment` → Delivery (Review)

If ambiguous, ask:
> "Is this document for someone to read and understand, or for assigning/tracking/verifying work?"

### Phase 1: Diátaxis Type Routing

| Question | Yes → Type |
|----------|-----------|
| Reader is new and will build something by following along? | **Tutorial** |
| Reader knows basics and wants to solve a specific problem? | **How-to Guide** |
| Reader wants to understand "why it was designed this way"? | **Explanation** |
| Reader needs exact specs/parameters/types? | **Reference** |

If unclear, ask:
> "Who is the primary reader, and what should they be able to do after reading?"

Multiple types per project are common — create separate files per type.

### Phase 1-D: Delivery Subtype Routing

| Question | Yes → Subtype |
|----------|--------------|
| Multi-agent work requiring Claude↔Codex handoff? | **Work Item** (bundle) |
| Assigns implementation work derived from RFC/ADR? | **Task** (standalone) |
| Agrees on interface/schema/SLA across modules/teams? | **Contract** (standalone) |
| Verifies Task completion item-by-item? | **Checklist** (standalone) |
| Evaluates completed Task results and records lessons? | **Review** (standalone) |

> **Work Item vs standalone:** Use Work Item bundle when multiple agents coordinate on one feature. Use standalone types for simple single-agent work.

### Phase 2: Agent Delegation

Route to the matching agent, passing all Phase 0 context:

**Diátaxis:** Tutorial → `doc-writer-tutorial` | How-to → `doc-writer-howto` | Explanation → `doc-writer-explain` | Reference → `doc-writer-reference`

**Delivery (standalone):** Task → `doc-writer-task` | Contract → `doc-writer-contract` | Checklist → `doc-writer-checklist` | Review → `doc-writer-review`

**Delivery (Work Item bundle):** Create `work/items/FEAT-NNN-slug/` directory, then delegate to agents in sequence: `doc-writer-task` (brief) → `doc-writer-contract` (contract) → `doc-writer-checklist` (checklist). Status and review are created later during execution.

### Phase 3: Quality Validation

> Common rules: `references/common-rules.md`. Style rules: `references/writing-style.md`.

For existing doc review requests, delegate to `doc-reviewer` agent.

After draft completion, verify:

**Universal checks:**
1. **Type purity**: No mixed-type content (e.g., Reference tables in Tutorial → split)
2. **Audience fit**: Can the target audience achieve their goal with this doc?
3. **6-month test**: Still valid in 6 months? No hardcoded volatile values?
4. **Term consistency**: Same concept never called by different names?
5. **Cross-references**: Links to related docs (including cross-axis)?
6. **Diagrams as Code**: Mermaid/PlantUML only?

**Delivery-axis additional checks:**
7. **Source link**: Brief/Task has RFC/ADR or Contract link?
8. **Acceptance criteria**: Completion criteria are verifiable?
9. **ID consistency**: Work Item files reference correct FEAT-NNN / T-NNN?
10. **Invariants**: Contract has at least 1 invariant?
11. **Boundaries**: Contract specifies allowed/forbidden modification zones?
12. **Status currency**: Status.md reflects actual state? (Work Item only)

---

## Partial Execution

| Request | Scope |
|---------|-------|
| "Write a doc" | Full Phase 0→3 |
| "Determine this doc's type" | Phase 0.5→1 only |
| "Review this doc" | Phase 3 only |
| "Add a Reference" | Phase 2 direct (type known) |
| "Write a Task" | Phase 2 direct (Delivery axis, Task) |
| "Create work item" | Phase 2 direct (Delivery axis, Work Item bundle) |
| "Set up doc structure" | Redirect to `/init-docs` |

---

## Explanation Subtypes: Design Doc vs ADR

| Subtype | Use Case | Scale |
|---------|----------|-------|
| **Design Doc (RFC)** | Full design proposal for new feature/system | Large change, needs review |
| **ADR** | Record of individual architecture decision | Small decision, history preservation |

Both handled by `doc-writer-explain` with internal template branching.

---

## Related Skills/Commands

- **`/init-docs`**: Initialize doc site structure (numbered hierarchy + MkDocs) + work item structure (`work/`)
- **diagram-architect**: Delegate for architecture diagrams in Explanation docs
- **doc-reviewer**: Comprehensive review of existing docs (both axes)

## Doc Site Architecture

For project-wide doc structure before writing individual docs:
> See `references/site-architecture.md` for numbering scheme (00-90), MkDocs config, and 5 governance rules.
> See `references/execution-rules.md` for Work Item bundle structure and multi-agent workflow.
> `/init-docs` auto-generates structure per these rules.
