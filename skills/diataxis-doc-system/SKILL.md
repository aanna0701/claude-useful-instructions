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

| Type | Purpose | Reader State |
|------|---------|-------------|
| **Tutorial** | Learning | First encounter |
| **How-to Guide** | Problem solving | Knows basics, has specific problem |
| **Explanation** | Understanding | Wants to know "why" |
| **Reference** | Information lookup | Needs exact specs |

### Delivery Axis (execution-oriented — action docs)

| Type | Purpose | When Used |
|------|---------|-----------|
| **Work Item** | Multi-agent coordination | Feature requiring Claude↔Codex handoff |
| **Task** | Standalone work assignment | Simple work derived from RFC/ADR |
| **Contract** | Interface agreement | Cross-module/team alignment |
| **Checklist** | Completion verification | Task acceptance |
| **Review** | Result assessment | Post-task completion |

**Work Item Bundle** = `brief.md` + `contract.md` + `checklist.md` + `status.md` + `review.md` co-located in `work/items/FEAT-NNN-slug/`. Primary pattern for multi-agent workflows.

---

## Workflow

### Phase 0: Input Gathering

**Required (ask if missing):** topic/scope, target audience, purpose.
**Optional:** existing codebase/docs, glossary, diagrams, source RFC/ADR.

### Phase 0.5: Axis Determination

- Understanding/learning/lookup → **Diátaxis** (Phase 1)
- Work assignment/interface/verification/assessment → **Delivery** (Phase 1-D)
- Keywords: `work item`, `task`, `contract`, `checklist`, `review` → Delivery
- If ambiguous, ask: "Is this for reading/understanding, or for assigning/tracking work?"

### Phase 1: Diátaxis Type Routing

| Reader State | Type |
|-------------|------|
| New, will build by following along | **Tutorial** |
| Knows basics, has specific problem | **How-to Guide** |
| Wants to understand "why" | **Explanation** |
| Needs exact specs/parameters | **Reference** |

### Phase 1-D: Delivery Subtype Routing

| Scenario | Subtype |
|----------|---------|
| Multi-agent Claude↔Codex handoff | **Work Item** (bundle) |
| Simple work from RFC/ADR | **Task** (standalone) |
| Interface/schema/SLA agreement | **Contract** (standalone) |
| Completion verification | **Checklist** (standalone) |
| Post-task assessment | **Review** (standalone) |

### Phase 2: Agent Delegation

Pass all Phase 0 context to the matching agent:

**Diátaxis:** Tutorial → `doc-writer-tutorial` | How-to → `doc-writer-howto` | Explanation → `doc-writer-explain` | Reference → `doc-writer-reference`

**Delivery (standalone):** Task → `doc-writer-task` | Contract → `doc-writer-contract` | Checklist → `doc-writer-checklist` | Review → `doc-writer-review`

**Work Item bundle:** Create `work/items/FEAT-NNN-slug/`, then: `doc-writer-task` (brief) → `doc-writer-contract` → `doc-writer-checklist`. Status and review created later.

### Phase 3: Quality Validation

> Rules: `references/common-rules.md`, `references/writing-style.md`.

For review requests, route by file location:
- `docs/` → `doc-reviewer` agent (Diataxis review)
- `work/` → `doc-reviewer-execution` agent (execution artifact review)

After draft completion, run review checklist from `references/common-rules.md` §6.

---

## Partial Execution

| Request | Scope |
|---------|-------|
| "Write a doc" | Full Phase 0→3 |
| "Determine this doc's type" | Phase 0.5→1 only |
| "Review this doc" | Phase 3 only |
| "Polish this doc" | Delegate to `/polish-doc` |
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
- **`/polish-doc`**: Apply writing-style and structural fixes directly to existing docs (counterpart to review)
- **diagram-architect**: Delegate for architecture diagrams in Explanation docs
- **doc-reviewer**: Review Diataxis docs (readability, type purity, style)
- **doc-reviewer-execution**: Review execution artifacts (structural integrity, contract compliance)
- **doc-polisher**: Apply fixes directly to docs (used by `/polish-doc`)

## Doc Site Architecture

For project-wide doc structure before writing individual docs:
> See `references/site-architecture.md` for numbering scheme (00-90), MkDocs config, and 5 governance rules.
> See `references/execution-rules.md` for Work Item rules; `references/execution-templates.md` for YAML templates.
> `/init-docs` auto-generates structure per these rules.
