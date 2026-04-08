# Claude-Codex Collaboration

## Roles

- **Claude**: spec owner, integrator — designs work items, reviews, merges, handles doc changes
- **Cursor**: scaffold + verify — scaffolds file structures (Composer), verifies implementation against contract
- **Codex**: implementer — per contract only, never modifies docs (records in `status.md`)

## State Machine

```
planned → [scaffolded] → implementing → ready-for-review → reviewing → merged
             ↑ optional                                       ↓
             (skip OK)                                      revising

planned → auditing → audited   ← AUDIT type only (/work-verify)
```

Valid transitions:
- `planned → scaffolded` — `/work-scaffold` (Cursor, optional)
- `planned → implementing` — `codex-run.sh` (skip scaffold)
- `scaffolded → implementing` — `codex-run.sh` (after Cursor scaffold)
- `planned → auditing` — `/work-verify` (AUDIT type only, Cursor)
- `auditing → audited` — Cursor writes `verify-result.md`

Illegal shortcuts:
- `planned → reviewing` (must implement first)
- `implementing → merged` (must review first)
- `reviewing → implementing` (only via REVISE → `revising`)

## Ownership

- `working_parent` is orchestration-only. Never implement there.
- Feature worktrees are the only implementation workspace.
- `status.md` in the active worktree is authoritative while work is in progress.
- Contract = single source of truth for boundaries.

## Worktree Rules (canonical)

All commands reference this section for worktree operations.

### Naming Convention (absolute paths)

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
PROJECT=$(basename "$REPO_ROOT")
SLUG="{TYPE}-NNN-slug"            # e.g. FEAT-001-user-auth
BRANCH="${TYPE_PREFIX}${SLUG}"    # e.g. feat/FEAT-001-user-auth
WT_PATH="$(dirname "$REPO_ROOT")/${PROJECT}-${SLUG}"
# e.g. /home/leo/projects/myapp-FEAT-001-user-auth
```

**All worktree paths MUST be absolute in output.** Cursor cannot resolve relative paths.

### Creation (only in `/work-plan`)

```bash
git branch "$BRANCH" "$PARENT"
git worktree add "$WT_PATH" "$BRANCH"
```

### Work Item Discovery (all commands)

Given an ID (e.g. `PERF-154`), find `work/items/{ID}-*/` in this order:

1. `work/items/{ID}-*/` in cwd (main repo — items not yet dispatched)
2. `git worktree list` → for each worktree path, check `{WT_PATH}/work/items/{ID}-*/`
3. Sibling directory fallback: `${PARENT}/${PROJECT}-{ID}-*/work/items/{ID}-*/`

First match wins. If no match: `ERROR: {ID} not found`.

### Worktree Resolution (all commands)

Once the item directory is found, resolve its worktree:

1. Read `Worktree Path` field from `status.md` (primary — always absolute)
2. Fallback: convention `$(dirname "$REPO_ROOT")/${PROJECT}-${SLUG}`
3. Verify: `git worktree list | grep "$SLUG"`
4. If missing and needed: recreate from branch `git worktree add "$WT_PATH" "$BRANCH"`

### Opening in Cursor

```bash
cursor "$WT_PATH"
# e.g. cursor /home/leo/projects/myapp-FEAT-001-user-auth
```

### File Resolution

Worktree copy is authoritative. Bootstrap: resolve slug → read `Worktree Path` from worktree `status.md` → fallback to convention → ALL subsequent reads use resolved absolute path.

## Relay Protocol

Each stage appends a structured block to `work/items/{SLUG}/relay.md` and posts a summary on the PR. This enables downstream stages to read prior results without re-deriving them.

### relay.md Format

```markdown
## {stage} @ {YYYY-MM-DD HH:MM}
result: {success | partial | revise | reject | blocked}
{stage-specific fields — see below}
notes: |
  {free-form summary, 1-3 lines}
```

Stage-specific fields:

| Stage | Fields |
|-------|--------|
| impl | `changed: [files]`, `commits: [hashes]` |
| verify | `passed: N`, `failed: N`, `failures: [- test: reason]` |
| review | `decision: {MERGE\|REVISE\|REJECT}`, `must_fix: N`, `optional: N`, `items: [- {SEV}: description (file:line)]` |
| revise | `fixed: [- description]`, `remaining: N` |

### Read Before Act

Each stage MUST read `relay.md` (if it exists) before starting:
- **verify**: Check impl stage result — skip if `blocked`.
- **review**: Check verify failures — factor into review severity.
- **revise**: Read review `items` — these are the MUST-fix list.

### PR Comment

After writing `relay.md`, post a summary comment on the PR (if PR exists in `status.md`):

```bash
gh pr comment {PR_NUMBER} --body "$(cat <<EOF
### {Stage} — {result}
{1-3 line summary from relay.md notes}
{for verify: passed/failed counts}
{for review: decision + must_fix count}
EOF
)"
```

Skip PR comment if no PR exists yet (e.g., during impl before push).

## Locks

- `work/locks/planning.lock` — prevents concurrent `/work-plan`
- `work/locks/{ID}.lock` — prevents concurrent impl and review on same item
- `work/locks/merge.lock` — one merge-and-cleanup at a time

## Review Revision Policy

- Review fixes stay on the same work item via `/work-revise`.
- New work item only when refactoring exceeds contract boundary.
- On REVISE, every MUST-fix from `review.md` must be resolved before optional work.

## Principles

- Codex: code + `status.md` only — never docs; records doc needs in "Doc Changes Needed"
- `working_parent` is not a scratchpad. Keep clean before planning, review, and merge.
- Ambiguities recorded in `status.md`, never resolved by implementer
- Draft PR creation happens at implementation stage, not review stage
- Human intervention: dispatch + review only
- Pipeline: plan(`/work-plan`) → scaffold(`/work-scaffold`→Cursor) → impl(`codex-run.sh`) → verify(`/work-verify`→Cursor) → review(`/work-review`). Each stage reads + writes `relay.md` per § Relay Protocol.
- Cursor/Codex fallback: `--claude` flag on scaffold/verify, `/work-impl` for implement
- AUDIT type items skip impl: `planned → auditing → audited` via `/work-verify`
- `/work-scaffold` and `/work-verify` auto-detect type from ID prefix
- `/work-scaffold` generates `.cursor/rules/*.mdc` for contract enforcement
- `/work-verify` generates Cursor prompt; Cursor writes `verify-result.md` directly
- All worktree paths in output MUST be absolute (Cursor cannot resolve relative paths)
