# write-doc — Diátaxis + Work Item Documentation

Thin CLI wrapper around `diataxis-doc-system` SKILL.md. Handles mode detection and file saving only — all workflow logic lives in SKILL.md.

Target: $ARGUMENTS (doc topic, or "review [filepath]")

---

## Step 0: Delegate

Delegate to `diataxis-doc-system` SKILL.md, passing all `$ARGUMENTS` as context. SKILL.md handles axis determination, type routing, and agent delegation.

---

## Step 1: File Saving

After agent completes, save output to the appropriate project location.

### Diataxis docs → `docs/`

Always use numbered hierarchy (MkDocs):

```
docs/
├── 00_context/          ← Explanation (business), Reference (requirements)
├── 10_architecture/     ← Explanation (design, ADR)
├── 20_implementation/   ← Reference (API, Config, CLI)
├── 30_guides/           ← Guides (organized by workflow)
│   ├── auth/
│   ├── deploy/
│   └── [workflow-name]/
├── 40_operations/       ← Guide (runbook), Explanation (monitoring), Reference (SLA)
└── 90_archive/
```

For Guide docs: place in `30_guides/[workflow-name]/`. If workflow folder doesn't exist, create it and update `30_guides/index.md` workflow map.

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

## Step 2: Completion Report

```
Document complete
─────────────────────────────────
Axis:     [Diataxis / Delivery]
Type:     [specific type]
Level:    [beginner / practitioner] (Guide only)
Workflow: [workflow name] (Guide only)
File:     [full path]
Audience: [reader or assignee]
─────────────────────────────────
Suggested related docs:
  - [cross-axis link suggestions]
```
