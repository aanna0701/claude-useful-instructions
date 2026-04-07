# Claude-Codex Collaboration Workflow

> **Doc type**: Explanation + Tutorial | **Audience**: Developers setting up multi-agent workflows

The `collab` bundle enables structured handoff between **Claude** (design/review) and **Codex** (implementation).

---

## Roles & Work Item Files

| Agent (Command) | Role | Writes |
|-------|------|--------|
| **Claude** (`/work-plan`, `/work-review`) | spec owner, integrator, final authority | brief.md, contract.md (signed), checklist.md, review.md |
| **Cursor / Antigravity** (`/work-scaffold`, `/work-verify`) | structure propagator, verifier (optional) | scaffolded files via Composer, verification reports via @Codebase |
| **Codex** (`/work-impl`) | implementer farm | code, status.md |

## Workflow (with optional Cursor / Antigravity phases)

```
Claude: /work-plan topic1, topic2, topic3
  → parallel agent generation + boundary check + dispatch manifest
                                          ↓
[OPTIONAL] — Human: /work-scaffold FEAT-001 FEAT-002
  → Copy prompt to Cursor/Antigravity Composer (Cmd+I) → scaffolds file structure
  → .cursor/rules/*.mdc generated in worktree
  → guard.mdc auto-enforces contract boundaries during editing
                                          ↓
TOUCH 1 — Human: bash codex-run.sh FEAT-001 FEAT-002 FEAT-003
  → auto: boundary check → seed artifacts → parallel codex exec → monitor
  → Codex implements per contract, records doc changes in status.md
  → prints: /work-review FEAT-001 FEAT-002 FEAT-003
                                          ↓
TOUCH 2 — Human: /work-review FEAT-001 FEAT-002 FEAT-003
  → Claude reviews in parallel, handles doc changes
  → MERGE: asks confirm → git merge + delete branch
  → REVISE: writes `review.md` MUST-fix items + re-runs `codex-run.sh`
```

### AUDIT Workflow (no implementation)

```
Claude: /work-plan --type=audit "naming convention check"
  → generates AUDIT-001 with Audit Scope + Audit Criteria
                                          ↓
Human: /work-verify AUDIT-001
  → Copy prompt to Cursor/Antigravity Chat → codebase audit
```

Review follow-up policy:
- Do not add a separate `work-refac` command for normal review changes.
- If the review fixes stay inside the existing contract, keep the same `FEAT-NNN` and use `/work-revise`.
- Only split out a new `REFACTOR-NNN` or `CHORE-NNN` item when the cleanup exceeds the original contract boundary or deserves separate tracking.

## Operating Model

The workflow is only stable if ownership is explicit:

- `working_parent` is orchestration-only
- feature worktrees are implementation-only
- the active worktree `status.md` is authoritative during implementation
- planning and merge operations mutate global state and must be serialized

If you treat the `working_parent` branch as a normal coding branch, the system will drift.

## State Machine

Use one overall state per work item:

| State | Meaning | Primary owner |
|------|---------|---------------|
| `planned` | Contract signed, not yet dispatched | Claude |
| `scaffolded` | Cursor/Antigravity scaffolding done (optional) | Cursor/Antigravity |
| `implementing` | Codex actively working | Codex |
| `blocked` | Preconditions or verification failed | Codex or Claude |
| `ready-for-review` | Implementation finished and verified | Codex |
| `reviewing` | Claude review in progress | Claude |
| `revising` | Review requested changes | Claude then Codex |
| `merged` | PR merged and branch cleaned up | Claude |
| `rejected` | Item closed without merge | Claude |
| `auditing` | Cursor/Antigravity audit in progress (AUDIT only) | Cursor / Antigravity |
| `audited` | Audit complete (AUDIT only) | Claude |

Transition graph:

```
planned -> [scaffolded] -> implementing -> ready-for-review -> reviewing -> merged
              ↑ optional      |                    |
                            blocked             revising -> implementing

planned -> auditing -> audited   ← AUDIT type only (no implementation)
```

`unknown` is not a valid business state. If tooling cannot determine a final outcome, it should write `blocked`.

## Architecture

```mermaid
graph LR
    subgraph "1 Claude — Design"
        A["/work-plan\n(parallel agents)"] --> B["work items +\nboundary check"]
    end

    subgraph "2 codex-run.sh"
        B --> BC["boundary check\n+ seed artifacts"]
        BC --> D["codex exec ×N\n(parallel)"]
        D --> E["code +\nstatus.md"]
    end

    subgraph "3 Claude — Review + Merge"
        E --> F["/work-review\n(parallel agents)"]
        F --> H["MERGE:\ngit merge + branch -d"]
        F --> DOC["doc changes\n(from status.md)"]
    end

    H -.->|REVISE| D
```

---

## Setup

### Step 1: Install collab bundle

```bash
./install.sh --collab /path/to/project
```

This installs everything: `.claude/` artifacts, `AGENTS.md`, `CLAUDE.md`, `codex-run.sh`, and the `lib/codex-run-*.sh` helpers. Creates `work/items/` directory.

### Installed Layout

```
project/
├── AGENTS.md                          # Codex reads this
├── CLAUDE.md                          # Claude reads this
├── codex-run.sh                       # Codex runner (single + parallel + boundary check)
├── lib/codex-run-*.sh                 # Runner helpers (work, git, boundary, runner)
├── work/items/                        # Work items (created by install.sh)
├── work/dispatch.json                 # Parallel dispatch manifest (created by /work-plan)
└── .claude/
    ├── rules/collab-workflow.md       # Auto-loaded 3-agent rules (Claude, Cursor/Antigravity, Codex)
    ├── commands/work-{plan,scaffold,verify,review,impl,revise,status}.md
    ├── agents/{issue-creator,work-reviser,cursor-prompt-builder}.md
    ├── skills/collab-workflow/
    ├── templates/work-item/*.md       # Brief, contract, checklist, status, review
    └── templates/cursor/*.md          # Cursor prompt templates + .cursor/rules/*.mdc templates
```

`/work-plan` seeds each worktree with its work item files and `AGENTS.md` by committing them on the feature branch. `codex-run.sh` re-seeds as a fallback if artifacts are missing.

---

## Worktree Support

`/work-plan` auto-creates a **FEAT-based worktree** per work item:

```
workspace/
├── VasIntelli-research/                    ← main repo (working_parent)
│   └── work/items/FEAT-001-slug/           ← work items (source of truth)
├── VasIntelli-research-FEAT-001-slug/      ← auto-created worktree
│   ├── AGENTS.md                           ← seeded from main repo
│   └── work/items/FEAT-001-slug/           ← seeded + committed on feature branch
└── VasIntelli-research-FEAT-002-slug/      ← auto-created worktree
    ├── AGENTS.md
    └── work/items/FEAT-002-slug/
```

### How it works

- `/work-plan` creates branch + worktree per FEAT, copies work item files + `AGENTS.md` into the worktree, and commits them on the feature branch (`chore(FEAT-NNN-slug): seed work item artifacts`)
- `codex-run.sh` resolves worktree from `status.md` Worktree Path; if artifacts are missing, it copies and commits them as a fallback
- On MERGE, `/work-review` runs `git worktree remove` + `git branch -d`
- Each worktree is temporary — exists only for the FEAT's lifetime
- Feature branch is deleted after merge, so the seed commit does not pollute history
- Runner monitoring depends on a single overall status in `status.md`. Keep frontmatter `status:` and body status aligned, and prefer the table fields from the template (`Status`, `Agent`, `Worktree Path`).
- If Codex exits without writing a final status, `codex-run.sh` now marks the item `blocked` with `runner-missing-status` instead of polling `unknown` indefinitely.

### Control Plane vs Data Plane

- Control plane: `working_parent`, batch manifests, locks, work-item planning files
- Data plane: feature worktrees, implementation commits, PR branches

Do not mix them. The most common source of breakage is editing production code directly on `working_parent` while the collab workflow is active.

### Preflight before implementation

A worktree existing on disk does not guarantee it is synced to the right base.

- `codex-run.sh` should first auto-sync the feature branch from the contract's `Parent Branch`.
- If upstream FEATs changed the expected file layout, verify those dependency outputs are already present in the worktree.
- If runner auto-sync fails or dependency outputs are still missing, do not start implementation. Resolve the branch state, then rerun `codex-run.sh`.
- For environment-dependent verification, prefer preinstalled dependencies and cached environments. If a network/package failure blocks completion, Codex should record `blocked` with the failing command rather than exiting silently.
- This prevents false-starts where Codex correctly blocks on missing invariant prerequisites such as moved files, split docs, or renamed paths.

---

## Parallel Codex Execution

`/work-plan` natively supports multiple topics — they are planned in parallel using concurrent agents, and the system automatically validates that their boundaries don't conflict.

### How it works

1. **Batch planning**: Pass multiple topics to `/work-plan` → each gets its own FEAT item, generated in parallel
2. **Boundary check**: After contracts are generated, the system checks that "Allowed Modifications" paths don't overlap between any pair of items
3. **Dispatch grouping**: Items with no boundary overlap are grouped for parallel execution; conflicting items are placed in sequential groups
4. **Batch manifest**: `work/batches/{batch_id}.json` records items, parallel groups, dependencies, and conflicts
5. **Latest pointer**: `work/dispatch.json` may mirror the current batch for convenience, but it is not the only source of truth

### Boundary matrix example

```
Boundary Check
──────────────────────────────────────────────
          FEAT-001    FEAT-002    FEAT-003
FEAT-001     —           ✓           ✓
FEAT-002     ✓           —           ⚠ OVERLAP
FEAT-003     ✓           ⚠ OVERLAP   —

⚠ FEAT-002 × FEAT-003: both modify src/utils/logger.py
```

Items with overlaps must run sequentially. The dispatch script enforces this automatically.

### Parallel execution with worktrees

Each Codex instance runs in its own terminal. With worktrees, each can also use its own worktree branch:

```bash
# Terminal 1 (VasIntelli-Training):
bash codex-run.sh FEAT-001

# Terminal 2 (VasIntelli-Inference):
bash codex-run.sh FEAT-002

# Terminal 3 (after 1 & 2 complete — boundary overlap):
bash codex-run.sh FEAT-003
```

## Locks and Serialization

Not everything should run in parallel.

- Planning is serialized with `work/locks/planning.lock`
- A single work item is serialized with `work/locks/{ID}.lock`
- Merge and cleanup are serialized with `work/locks/merge.lock`

Recommended safe concurrency:
- parallel planning agents inside one `/work-plan` call
- parallel Codex implementation on disjoint items
- parallel review analysis across items

Recommended serialization:
- multiple `/work-plan` invocations
- merge execution on `working_parent`
- doc sync or cleanup that mutates shared manifests

---

## Walkthrough: JWT Authentication Middleware

> Follow this end-to-end example to understand the full workflow.

### Phase 1 — Design (Claude)

```
[Claude] /work-plan "Add JWT authentication middleware"

Claude: reviews scope → generates contract → signs (status: draft → signed)

Created work/items/FEAT-001-jwt-auth-middleware/
  brief.md, contract.md (signed), checklist.md, status.md (planned)

Codex Command: bash codex-run.sh FEAT-001
```

### Phase 2 — Implement (Codex)

```
[Codex] bash codex-run.sh FEAT-001
  → Reads brief → contract → checklist
  → Updates status.md (implementing)
  → Implements within contract boundaries (src/middleware/, tests/middleware/)
  → Commits: feat(FEAT-001): add JWT validation middleware
  → Updates status.md → ready-for-review (5/5 checklist items)
```

### Phase 3 — Review + Merge (Claude)

```
[Claude] /work-review FEAT-001

Claude:
  → review.md: MERGE
  → asks user to confirm → git merge + delete branch
  → applies doc changes from status.md
```

Decision flow:
- **MERGE** → ask user → `git merge feat/FEAT-NNN-*` → `git branch -d feat/FEAT-NNN-*` → apply doc changes → merged
- **REVISE** → write concrete `MUST-fix` items to `review.md` + `bash codex-run.sh FEAT-NNN` → `codex-run.sh` injects `review.md` into the prompt → Codex fixes those items first → re-review
- **REJECT** → close work item with reason

## Safety Checklist

Before `/work-plan`:
- `working_parent` is clean or only has deliberate planning-file changes
- no existing planning lock

Before `codex-run.sh`:
- target worktrees exist
- no item lock conflict
- dependency FEAT outputs are already present if required
- if the project uses uv, `uv sync --frozen` succeeds before Codex starts

Before `/work-review`:
- item is `ready-for-review`
- `working_parent` is clean
- no merge lock

Before merge:
- parent freshness passes
- PR exists and matches the feature branch
- cleanup targets only the reviewed item

---

---

## Cursor / Antigravity Integration

The collab workflow supports optional Cursor/Antigravity phases for multi-file scaffolding and codebase-wide verification.

### Full Pipeline: `/collab-workflow`

Type `/collab-workflow {instruction}` in Cursor or Antigravity. The IDE AI orchestrates, delegating each step to the best tool:

```
User: /collab-workflow JWT 인증 미들웨어 추가해줘

AI:   [Step 1] → claude -p "...work-plan..."           → "FEAT-153 계획 확인해주세요"
User: ㅇㅋ
AI:   [Step 2] → creates file stubs directly            → "구조 확인해주세요"
User: 진행
AI:   [Step 3] → bash codex-run.sh FEAT-153             → "구현 결과 확인해주세요"
User: ok
AI:   [Step 4] → searches codebase, checks contract     → "검증 결과 확인해주세요"
User: next
AI:   [Step 5] → claude -p "...work-review..."          → "머지할까요?"
```

Each tool does what it's best at: Claude for specs/review, Codex for implementation, IDE AI for scaffolding/verification.

`./install.sh --collab` installs pipeline artifacts to `.cursor/rules/collab-pipeline.mdc`, `.agent/workflows/collab-pipeline.md`, and `AGENTS.md`. The shared step-by-step text lives only in **`templates/collab-pipeline-body.md`** in claude-useful-instructions; the installer prepends tool-specific frontmatter so Cursor and Antigravity stay in sync. Bundled skills (e.g. `collab-workflow`) are installed **only** under `.claude/skills/<name>/`.

### Standalone commands (for step-by-step use)

- **`/work-scaffold`**: Generate Composer prompts + `.cursor/rules/*.mdc` (contract enforcement)
- **`/work-verify`**: AUDIT-only — codebase audit; `--ingest` parses results
- **FEAT/REFAC**: Skip `/work-verify` — go directly from `codex-run.sh` to `/work-review`

All Cursor/Antigravity phases are optional. Skip them to use the original 2-touch workflow.

> Full guide: [Cursor/Antigravity Integration](cursor-integration.md)

---

See `rules/collab-workflow.md` for the compact command table.
