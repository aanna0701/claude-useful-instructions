# write-doc — Diátaxis + Work Item Documentation

Write high-quality documents by determining type via the Diátaxis + Work Item framework and delegating to specialized agents.

Target: $ARGUMENTS (doc topic, or "review [filepath]")

---

## Step 0: Mode Detection

Analyze `$ARGUMENTS`:

| Pattern | Mode | Action |
|---------|------|--------|
| `review [filepath]` | Review existing doc | → Step 5 |
| `work-item [topic]` | Work Item bundle | → Step 3-WI |
| `task [topic]` | Task creation | → Step 3 (Delivery, Task) |
| `contract [topic]` | Contract creation | → Step 3 (Delivery, Contract) |
| `checklist [T-NNN]` | Checklist creation | → Step 3 (Delivery, Checklist) |
| `review-doc [T-NNN]` | Review creation | → Step 3 (Delivery, Review) |
| Other | New document | → Step 1 |

---

## Step 1: Input Gathering

Confirm with user (skip if already in conversation):

**Required:** Document topic/scope, target audience (newcomer? peer dev? management?)

**Optional:** Codebase path, glossary path, existing reference docs

---

## Step 1.5: Axis Determination

Apply axis determination routing from SKILL.md Phase 0.5.

Show determination result to user for confirmation:
```
Axis: [Diátaxis / Delivery]
```

---

## Step 2: Diátaxis Type Routing

Apply Diátaxis type routing from SKILL.md Phase 1.

Show result to user:
```
Axis:   Diátaxis
Type:   [Tutorial / How-to Guide / Explanation / Reference]
Reader: [target audience]
Outcome: [what reader can do after reading]
```

---

## Step 2-D: Delivery Subtype Routing

If entering from Step 0 with explicit keyword, subtype is already determined. Otherwise apply Delivery subtype routing from SKILL.md Phase 1-D.

Show result to user:
```
Axis:    Delivery (Execution Artifact)
Type:    [Task / Contract / Checklist / Review]
Target:  [assignee or contracting party]
Purpose: [assignment / agreement / verification / assessment]
```

---

## Step 3: Agent Delegation

Delegate to the matching agent per SKILL.md Phase 2, passing Step 1 context.

---

## Step 3-WI: Work Item Bundle Creation

For `work-item` mode. Creates all 3 design-phase files in sequence.

1. **Assign ID**: Glob `work/items/` for existing directories, assign next `FEAT-NNN`
2. **Create directory**: `work/items/FEAT-NNN-slug/`
3. **Delegate brief**: → `doc-writer-task` (brief mode), passing topic + source RFC/ADR
4. **Delegate contract**: → `doc-writer-contract` (bundle mode), passing brief context
5. **Delegate checklist**: → `doc-writer-checklist` (bundle mode), passing brief + contract context
6. **Create status.md**: Initialize with `status: open`, `agent: [TBD]`

> `review.md` is NOT created now — written by Claude after implementation completes.

Show to user:
```
Work Item FEAT-NNN created
  work/items/FEAT-NNN-slug/
    brief.md      ✓
    contract.md   ✓
    checklist.md  ✓
    status.md     ✓ (initialized)
    review.md     — (post-implementation)
```

→ Skip to Step 5.

---

## Step 4: File Saving

Save the agent's output to the appropriate project location.

### Diátaxis docs → `docs/`

**Structure detection:** If `docs/00_context/` exists, use numbered hierarchy; otherwise use type-based layout.

#### Numbered hierarchy (when docs/00_context/ exists)
```
docs/
├── 00_context/          ← Explanation (business), Reference (requirements)
├── 10_architecture/     ← Explanation (design, ADR)
├── 20_implementation/   ← Reference (API, Config, CLI)
├── 30_guides/           ← Tutorial, How-to
│   ├── tutorials/
│   └── howto/
├── 40_operations/       ← How-to (deploy, runbook), Reference (SLA)
└── 90_archive/
```

#### Type-based layout (default)
```
docs/
├── tutorials/      ← Tutorial
├── howto/          ← How-to Guide
├── explanation/    ← Explanation (Design Doc, ADR)
│   └── adr/
└── reference/      ← Reference
```

### Work Item bundles → `work/items/`

```
work/items/FEAT-NNN-slug/
├── brief.md        ← Work overview
├── contract.md     ← Implementation boundaries
├── checklist.md    ← Completion verification
├── status.md       ← Real-time state
└── review.md       ← Post-completion assessment
```

### Standalone execution docs → `work/`

```
work/
├── tasks/          ← Task (T-NNN-slug.md)
├── contracts/      ← Contract ({domain}-contract.md)
├── checklists/     ← Checklist (T-NNN.md)
└── reviews/        ← Review (T-NNN-review.md)
```

If `work/` does not exist, prompt user to run `/init-docs` first.

### Common rules

Filenames: kebab-case only. If numbered hierarchy is missing, suggest `/init-docs`.

---

## Step 5: Quality Validation (includes review mode)

For existing doc review or new doc validation.

> **Review mode:** Delegate to `doc-reviewer` agent for comprehensive readability/type-purity/governance review.

### Type purity (Diátaxis)
- [ ] No Reference tables inside Tutorial?
- [ ] No beginner explanations inside How-to?
- [ ] No step-by-step procedures inside Explanation?
- [ ] No opinions/recommendations inside Reference?

### Type purity (Delivery)
- [ ] No design discussion in Brief/Task? (→ split to Explanation)
- [ ] No procedural guides in Contract? (→ split to How-to)
- [ ] No background explanations in Checklist?
- [ ] No new requirements in Review? (→ split to new Work Item)

### Common quality
- [ ] Complete YAML frontmatter? (title, type, status + type-specific fields)
- [ ] Diagrams in Mermaid/PlantUML?
- [ ] Terms match glossary?
- [ ] Cross-reference links present (including cross-axis)?
- [ ] Valid in 6 months?

### Delivery-axis additional
- [ ] Brief/Task has source link (RFC/ADR or Contract)?
- [ ] Completion criteria are verifiable?
- [ ] Work Item files reference correct FEAT-NNN / T-NNN?
- [ ] Contract has at least 1 invariant?
- [ ] Contract specifies allowed/forbidden modification zones?
- [ ] Review has at least 1 lesson learned?

### Work Item bundle additional
- [ ] All 5 files present in `work/items/FEAT-NNN-slug/`?
- [ ] Status.md reflects actual state?
- [ ] Brief → Contract → Checklist are internally consistent?

### Governance
- [ ] `owner` field set?
- [ ] No duplicate info across docs (SSOT)?
- [ ] `tags` use only project-allowed values?

Fix violations, confirm with user, then apply.

---

## Step 6: Completion Report

```
Document complete
─────────────────────────────────
Axis:     [Diátaxis / Delivery]
Type:     [Tutorial / How-to / Explanation / Reference / Work Item / Task / Contract / Checklist / Review]
File:     [docs/ or work/][path]/[filename].md
Audience: [reader or assignee or implementing agent]
Quality:  PASS (or WARN N items fixed)
─────────────────────────────────
Suggested related docs:
  - [missing related doc type suggestions]
  - [cross-axis link suggestions (e.g., Brief → related RFC)]
```
