# write-doc — Diátaxis + Work Item Documentation

Thin routing wrapper around `diataxis-doc-system` SKILL.md. This command handles mode detection, file paths, and work-item bundling. The SKILL.md handles the actual workflow logic (axis determination, type routing, agent delegation, quality validation).

Target: $ARGUMENTS (doc topic, or "review [filepath]")

---

## Step 0: Mode Detection

Analyze `$ARGUMENTS`:

| Pattern | Mode | Action |
|---------|------|--------|
| `review [filepath]` | Review existing doc | → SKILL.md Phase 3 |
| `work-item [topic]` | Work Item bundle | → Step 3-WI |
| `task [topic]` | Task creation | → Step 2 (Delivery, Task) |
| `contract [topic]` | Contract creation | → Step 2 (Delivery, Contract) |
| `checklist [T-NNN]` | Checklist creation | → Step 2 (Delivery, Checklist) |
| `review-doc [T-NNN]` | Review creation | → Step 2 (Delivery, Review) |
| Other | New document | → Step 1 |

---

## Step 1: Input Gathering

Gather required and optional inputs per SKILL.md Phase 0. Confirm topic, audience, and purpose with user (skip if already in conversation).

---

## Step 1.5: Axis Determination

Apply SKILL.md Phase 0.5. Show result to user for confirmation:
```
Axis: [Diátaxis / Delivery]
```

---

## Step 2: Type Routing & Agent Delegation

Apply SKILL.md Phase 1 (or Phase 1-D for Delivery axis) to determine type, then Phase 2 to delegate to the matching agent.

Show determination to user before delegating:
```
Axis:   [Diátaxis / Delivery]
Type:   [Tutorial / How-to Guide / Explanation / Reference / Task / Contract / Checklist / Review]
Agent:  [doc-writer-*]
```

→ After agent completes, go to Step 4.

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
    brief.md      done
    contract.md   done
    checklist.md  done
    status.md     done (initialized)
    review.md     — (post-implementation)
```

→ Quality validation per SKILL.md Phase 3, then Step 5.

---

## Step 4: File Saving

Save the agent's output to the appropriate project location.

### Diataxis docs → `docs/`

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

Filenames: kebab-case only.

---

## Step 5: Completion Report

```
Document complete
─────────────────────────────────
Axis:     [Diataxis / Delivery]
Type:     [specific type]
File:     [full path]
Audience: [reader or assignee]
─────────────────────────────────
Suggested related docs:
  - [cross-axis link suggestions]
```
