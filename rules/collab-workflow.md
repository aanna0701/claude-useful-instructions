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

Each stage MUST read prior relay results before starting:
- **verify**: Check impl stage result — skip if `blocked`.
- **review**: Check verify failures — factor into review severity.
- **revise**: Read review `items` — these are the MUST-fix list.

**Read sources (priority order):**
1. MCP `get_pull_request_comments` — freshest, works across AIs (Claude Code, Codex, Cursor)
2. Local `relay.md` — fallback if MCP unavailable or PR not yet created

### PR Comment Relay (Cross-AI via MCP)

PR comments are the **universal relay** readable by all AIs (Claude Code, Codex, Cursor) via GitHub MCP server (`@modelcontextprotocol/server-github`).

#### Write (after each stage)

After writing local `relay.md`, use MCP `add_issue_comment` (or fallback `gh pr comment`) to post a structured comment on the PR:

```markdown
<!-- relay:{stage}:{ISO-8601} -->
### {stage} — {result}
**agent:** {codex|claude-code|cursor|human}
**{field1}:** value1
**{field2}:** value2

> Summary notes as blockquote.
```

Stage-specific fields:

| Stage | Required Fields |
|-------|----------------|
| impl | `changed`, `commits` |
| verify | `passed`, `failed`, `failures` (if any) |
| review | `decision` (MERGE/REVISE/REJECT), `must_fix`, `items` (if any) |
| revise | `fixed`, `remaining` |

#### Read (before each stage)

Use MCP `get_pull_request_comments` to fetch PR comments. Filter by `<!-- relay:{prev_stage}: -->` marker. Use the last matching comment (handles revise cycles).

```
PR_NUMBER = extract from status.md PR field
comments = MCP get_pull_request_comments(owner, repo, PR_NUMBER)
prev_relay = last comment containing "<!-- relay:{prev_stage}:"
Parse: result, changed, failures, etc. from **bold-key:** lines
```

Fallback if MCP unavailable: read local `relay.md`.

#### Issue Status Labels

Use MCP `update_issue` to swap `status:*` labels at each state transition:

```
status:planned → status:scaffolded → status:implementing →
status:ready-for-review → status:revising → status:merged
```

Any AI can use MCP `get_issue` to check current status before acting.
Fallback: `gh issue edit --remove-label/--add-label`.

Skip if no Issue exists in `status.md`.

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
