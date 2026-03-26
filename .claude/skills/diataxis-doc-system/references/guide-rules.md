# Guide Writing Rules

Rules that `doc-writer-guide` agent must Read before writing.

## Identity

Guide = document for **Doing** — step-by-step procedures that lead to a concrete result.
Replaces both Tutorial and How-to Guide from classic Diátaxis.

A single Guide covers one topic at the appropriate depth, determined by `level`:

| Level | Reader | Style | Example |
|-------|--------|-------|---------|
| `beginner` | First encounter, builds by following along | Golden path, no choices, checkpoints | "Getting Started with Auth" |
| `practitioner` | Knows basics, solving a specific problem | Flexible, production-ready, concise | "How to Rotate API Tokens" |

## DO / DON'T

| DO | DON'T |
|----|-------|
| **One guide = one outcome** | Solve 3+ problems in one doc |
| State **prerequisites** explicitly | Teach from scratch when level=practitioner |
| Provide **verifiable results** at each step | List 10 steps with no checkpoints |
| Keep explanations **minimal** | Lengthy background theory (-> Explanation) |
| Use **production-ready** examples | `foo`/`bar` toy values |
| **Link** to Reference for full parameter lists | List every option exhaustively |

## Document Structure Template

```markdown
# [Action Verb] [Concrete Outcome]

> [One-sentence: what the reader will achieve]
> Level: beginner | practitioner
> Estimated time: [N] minutes (beginner only)

## Prerequisites
- [Tool / knowledge] — verify: `command` (beginner: show verify command)
- [Prior guide link] (practitioner: "This guide assumes [prior guide]")

## Procedure

### 1. [Start with a verb]
[Why this step — one sentence]
\```bash
concrete_command --with=real_value
\```
✅ **Check**: [Expected result]

> 💡 **Variation** (practitioner only): PostgreSQL: `pg_dump`; MySQL: `mysqldump`

### 2. [Start with a verb]
...

## Verify the Result
[How to confirm the final outcome is correct]

## Troubleshooting (optional)
| Symptom | Cause | Fix |
|---------|-------|-----|
| [Error message] | [Root cause] | [Command or link] |

## Next Steps
- [Related Guide link]: Try [next task]
- [Explanation link]: Learn why this works
- [Reference link]: Full parameter details
```

## Core Rules

1. **Level Selection** — Set `level` in frontmatter. Beginner: golden path, no choices, every step shown. Practitioner: acknowledge environment variance, trust competence, skip basics.
2. **Checkpoint Pattern** — End every step with `✅ Check:`. Non-negotiable for both levels.
3. **Title** — Start with a verb. Beginner: "[Verb] [What You'll Build]". Practitioner: "How to [solve specific problem]".
4. **Prerequisite Gate** — Beginner: tool verification commands. Practitioner: link to beginner guide ("assumes you completed [Guide title]").
5. **Flexibility** — Beginner: one path only, OS branches via tabs/toggles. Practitioner: acknowledge choices, 3+ options -> table.
6. **Code Blocks** — Copy-pasteable. Unavoidable placeholders: `YOUR_API_KEY` (UPPER_SNAKE_CASE). Separate input from output.
7. **Scope** — 10 steps max (split into parts if exceeded). One action per step.
8. **No Duplication** — If content exists in another doc, link to it. Never copy Reference tables or Explanation theory into a Guide.

## Workflow Organization

Guides are organized by **workflow** — a sequence of steps that accomplish a business-level goal (e.g., "Authentication", "Deployment", "Data Migration").

### Workflow Map

Before writing individual guides, define the project's workflows in `docs/30_guides/index.md`:

```markdown
## Workflows

| Workflow | Guides | Reference | Explanation |
|----------|--------|-----------|-------------|
| Authentication | [Getting Started](auth/getting-started.md), [Add OAuth](auth/add-oauth-provider.md) | [Auth API](../20_implementation/auth-api.md) | [Why JWT](../10_architecture/auth-strategy.md) |
| Deployment | [First Deploy](deploy/first-deploy.md), [Rollback](deploy/rollback.md) | [CI/CD Config](../20_implementation/cicd-config.md) | [Deploy Architecture](../10_architecture/deploy-overview.md) |
```

### Folder Structure

Guides are grouped by workflow topic, not by level:

```
docs/30_guides/
├── index.md              # Workflow map (all workflows listed)
├── auth/                 # Auth workflow
│   ├── getting-started.md    # [beginner]
│   └── add-oauth-provider.md # [practitioner]
├── deploy/               # Deploy workflow
│   ├── first-deploy.md       # [beginner]
│   └── rollback.md           # [practitioner]
└── data/                 # Data workflow
    ├── first-migration.md    # [beginner]
    └── zero-downtime-migration.md # [practitioner]
```

### Workflow Discovery (Phase 0)

Before writing a Guide, check if its workflow already exists:
1. Read `docs/30_guides/index.md` for existing workflows
2. If workflow exists -> place the new guide in that workflow folder
3. If workflow is new -> create the folder, add entry to workflow map
4. Link beginner <-> practitioner guides within the same workflow

### Sequencing Within a Workflow

- Beginner guides come first (prerequisite for practitioner guides)
- Practitioner guides link back to the beginner guide as prerequisite
- Each guide links to relevant Reference and Explanation docs in the same workflow

## Tone & Style

- **Beginner**: Second person, present tense. Encouraging but not patronizing.
- **Practitioner**: Direct and practical. Trust the reader's competence.

## Anti-Patterns

1. **"Lecture Guide"**: 3-paragraph theory inserted mid-step -> link to Explanation
2. **"Reference in Disguise"**: Lists every option and parameter -> link to Reference
3. **"Choose-Your-Own Guide"**: Repeated "pick A or B" in a beginner guide
4. **"Blind Guide"**: Steps with no intermediate checkpoints
5. **"Swiss Army Guide"**: Solves 3+ unrelated problems in one doc -> split
