# Claude-Codex Collaboration Workflow (v2)

> **Doc type**: Explanation + Tutorial | **Audience**: Developers setting up multi-agent workflows

The `collab` bundle enables structured handoff between **Claude** (design/review) and **Codex** (implementation). v2 is **PR-native**: state is derived from the GitHub PR + git, never stored in per-item md files.

See [Migration v1 → v2](MIGRATION-v2.md) if you're coming from v1.

---

## Roles

| Agent (Command) | Role |
|-----------------|------|
| **Claude** (`/work-plan`, `/work-review`, `/work-status`) | spec owner, reviewer, integrator. Can also run `/work-impl`/`/work-refactor` (tries Codex first, falls back in-session). |
| **Cursor** (`/work-impl`, `/work-refactor` from `.cursor/commands/`) | interactive implementer — opens the worktree in Composer for coordinated multi-file edits |
| **Codex** (`codex-run.sh`, invoked by Claude `/work-impl` / `/work-refactor`) | unattended implementer — best for running many items in parallel |
| **CI** (`.github/workflows/pr-checks.yml`) | verifier (ruff + mypy + pytest for Python; adapt per stack) |

Per work item, exactly **one** file is written: `work/items/{ID}-{slug}/contract.md`. Everything else (status, verification, review decisions) lives on the PR itself.

## Pipeline (4 stages)

```
/work-plan → /work-impl | /work-refactor → /work-review → merge
```

```
[Claude] /work-plan "Add JWT middleware"
  → creates contract.md, branch feature-feat-{slug}, worktree, draft PR

[Codex / Claude / Cursor] /work-impl FEAT-001
  → Claude session: tries `codex-run.sh FEAT-001` first; falls back in-session if Codex stalls
  → Cursor session: opens the worktree, runs /work-impl from .cursor/commands/ (Composer multi-file edit)
  → Unattended: bash codex-run.sh FEAT-001 directly
  → All three read the same inputs (contract + unresolved threads + diff)
  → small commits, -s for DCO, push
  → promotes draft → ready when checks green

[Claude] /work-review FEAT-001
  → MERGE: squash merge + branch/worktree cleanup
  → CHANGES_REQUESTED: unresolved threads are MUST-fix on re-entry
```

### Re-entry (revise)

No separate `/work-revise` command. If `reviewDecision=CHANGES_REQUESTED`, re-run `/work-impl {ID}` (or `/work-refactor`). The command fetches unresolved review threads via GraphQL and injects each as a MUST-fix. After fixing, call `resolveReviewThread` to close each thread.

## State (derived, never stored)

State is computed from PR fields on each `/work-status` call:

| Computed state | Derivation |
|----------------|------------|
| `planned` | Draft PR exists, no commits beyond seed |
| `implementing` | Draft PR, commits being pushed |
| `ready-for-review` | PR marked Ready, checks green |
| `changes-requested` | `reviewDecision=CHANGES_REQUESTED` |
| `merged` | PR merged (squash) |

No `status.md`, no labels, no relay files.

## Branch + Worktree Model

`/work-plan` creates a branch `feature-{type}-{slug}` and a worktree under `<repo>-{ID}-{slug}/`. Each item lives in its own worktree for the duration of the PR. On merge, `/work-review` removes the worktree and deletes the branch.

- Branch naming: `feature-{type}-{slug}` only (legacy `feature-{slug}` rejected).
- Merge strategy: **squash only**.
- Control plane (main repo / trunk) vs data plane (worktree) — don't mix.

## Worktree PID isolation

Worktree directory names include a ppid suffix so concurrent `/work-plan` sessions don't collide on the same slug. See `work/items/{ID}-{slug}/contract.md` — the `Worktree` field is the authoritative path.

## Parallel Planning

`/work-plan` accepts multiple topics and generates contracts in parallel, then runs a boundary check on `Touch` globs. Items with overlapping globs are grouped for sequential execution; disjoint items can run in parallel via separate `/work-impl {ID}` invocations.

## Locks

Serialize operations that mutate shared state:

- `work/locks/planning.lock` — only one `/work-plan` at a time
- `work/locks/merge.lock` — only one merge at a time

Parallel-safe:

- Multiple `/work-impl` invocations on disjoint items
- Review analysis across items

## Safety Checklist

Before `/work-plan`:
- Trunk is clean or only has deliberate planning changes
- No existing planning lock

Before `/work-impl` / `/work-refactor`:
- Worktree exists (created by `/work-plan`)
- Draft PR exists for the branch
- If the project uses `uv`, `uv sync --frozen` succeeds

Before merge (inside `/work-review`):
- CI green
- `reviewDecision != CHANGES_REQUESTED`
- No merge lock held

## Setup

```bash
./install.sh /path/to/project
```

Installs `.claude/` artifacts, `AGENTS.md`, `CLAUDE.md`, `codex-run.sh`, `lib/codex-run-*.sh`, pre-commit hooks, and `.github/workflows/pr-checks.yml`. Creates `work/items/` and `work/locks/`.

### Installed Layout

```
project/
├── AGENTS.md                          # Codex reads this
├── CLAUDE.md                          # Claude reads this
├── codex-run.sh                       # Unattended Codex runner (stall detection)
├── lib/codex-run-*.sh                 # Runner helpers
├── work/
│   ├── items/                         # Per-item: contract.md only
│   └── locks/                         # planning.lock, merge.lock
├── .github/workflows/pr-checks.yml    # CI (required)
├── .claude/
│   ├── rules/{collab-workflow,review-merge-policy}.md
│   ├── commands/work-{plan,impl,refactor,review,status}.md
│   ├── agents/pr-reviewer.md
│   ├── skills/collab-workflow/SKILL.md
│   └── templates/work-item/contract.md
└── .cursor/
    ├── commands/work-{impl,refactor}.md   # Cursor-side implementer commands
    └── rules/collab-pipeline.mdc          # shared pipeline overview
```

## See Also

- [Commands Reference](commands.md) — full command list
- [Migration v1 → v2](MIGRATION-v2.md) — what changed and how to upgrade
- `rules/collab-workflow.md` — compact command table loaded into every session
