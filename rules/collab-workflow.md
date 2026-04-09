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

- The **current project branch** is orchestration-only. Never implement there directly.
- Feature worktrees are the only implementation workspace.
- `status.md` in the active worktree is authoritative while work is in progress.
- Contract = single source of truth for boundaries.
- No `branch-map.yaml` needed — base branch = `git rev-parse --abbrev-ref HEAD`.

## Hook-Enforced Workflow

All code modifications go through hooks that enforce the worktree + issue + PR pattern:

1. **branch-naming** (PreToolUse): Enforces `feature-*` naming on all new branches. `feat` → `feature-{slug}`, others → `feature-{type}-{slug}`.
2. **guard-branch** (PreToolUse): Blocks code edits on the main repo. Auto-creates a worktree + GitHub Issue. Worktrees are exempt.
3. **auto-pr-commit** (PostToolUse): On first `git commit` in a worktree, pushes the branch and creates a draft PR (base = branch the worktree was created from).
4. **worktree-cleanup** (PostToolUse + Stop): After `gh pr merge` or on session end, deletes merged worktrees, local branches, and remote branches.
5. **auto-pr** (Stop): Fallback PR creation if the PostToolUse hook didn't fire.
6. **pre-commit** (git hook): Runs ruff, pyright, mypy, clang-format before every commit.

## Worktree Rules (canonical)

All commands reference this section for worktree operations.

### Naming Convention (absolute paths)

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
PROJECT=$(basename "$REPO_ROOT")
SLUG="user-auth"                         # kebab-case, max 30 chars
# feat → feature-{slug}, others → feature-{type}-{slug}
BRANCH="feature-${SLUG}"                 # e.g. feature-user-auth
BRANCH="feature-fix-${SLUG}"             # e.g. feature-fix-login-crash
BRANCH="feature-refac-${SLUG}"           # e.g. feature-refac-db-schema
WT_PATH="$(dirname "$REPO_ROOT")/${PROJECT}-${BRANCH}"
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
1. `gh api` direct — freshest (Claude Code, codex-run.sh)
2. `pr-relay.md` in worktree — pre-fetched snapshot (Codex, Cursor)
3. Local `relay.md` — fallback if PR not yet created

### PR Comment Relay (Cross-AI Hybrid)

PR comments are the **universal relay**. Write via MCP `add_issue_comment` or `gh pr comment`. Read via `gh api` (direct) or pre-fetched `pr-relay.md` (for sandboxed AIs).

**Note:** MCP `get_pull_request_comments` returns **review comments only** (inline code comments), NOT issue comments. Use `gh api` to read relay comments.

| AI | Write | Read |
|----|-------|------|
| Claude Code | MCP `add_issue_comment` or `gh pr comment` | `gh api .../issues/{n}/comments` direct |
| Codex | MCP `add_issue_comment` (if available) or relay.md only → codex-run.sh posts | `pr-relay.md` (pre-fetched by codex-run.sh) |
| Cursor | MCP `add_issue_comment` (if available) or relay.md only → user triggers post | `pr-relay.md` (pre-fetched during scaffold/verify) |

#### Write (after each stage)

After writing local `relay.md`, post a structured comment on the PR:

```markdown
<!-- relay:{stage}:{ISO-8601} -->
### {stage} — {result}
**agent:** {codex|claude-code|cursor|human}
**{field1}:** value1
**{field2}:** value2

> Summary notes as blockquote.
```

Methods (try in order): MCP `add_issue_comment` → `gh pr comment` → skip (relay.md suffices).

**CRITICAL: Use the PR number, NOT the Issue number.** GitHub's API treats PRs as issues internally, so `add_issue_comment` works on PR numbers. Posting to the Issue number scatters relay history away from the code.

Resolve PR number: parse `status.md` PR field → extract number from URL (e.g., `.../pull/42` → `42`). If no PR yet, skip relay comment.

❌ WRONG — posting to Issue number:
```
# Issue field: https://github.com/org/repo/issues/233
add_issue_comment(issue_number=233, body="<!-- relay:verify:... -->")
# → comment lands on ISSUE, not on PR
```

✅ RIGHT — posting to PR number:
```
# PR field: https://github.com/org/repo/pull/234
add_issue_comment(issue_number=234, body="<!-- relay:verify:... -->")
# → comment lands on PR where all relay lives
```

✅ RIGHT — fallback with gh CLI:
```bash
gh pr comment 234 --body "<!-- relay:verify:... -->"
```

Stage-specific fields:

| Stage | Required Fields |
|-------|----------------|
| impl | `changed`, `commits` |
| verify | `passed`, `failed`, `failures` (if any) |
| review | `decision` (MERGE/REVISE/REJECT), `must_fix`, `items` (if any) |
| revise | `fixed`, `remaining` |

#### Read (before each stage)

**Claude Code** (direct):
```bash
PR_NUMBER=$(grep -oP '^\| PR \| .*/pull/\K\d+' "$WT_PATH/work/items/$SLUG/status.md")
OWNER_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
gh api "repos/${OWNER_REPO}/issues/${PR_NUMBER}/comments" \
  --jq '[.[] | select(.body | contains("<!-- relay:")) | .body] | last'
```

**Codex / Cursor** (pre-fetched file):
Read `$WT_PATH/work/items/{SLUG}/pr-relay.md`. Filter for `<!-- relay:{prev_stage}: -->` marker. Use the last matching block.

#### Pre-fetch (for Codex/Cursor)

Before dispatching to Codex or generating Cursor prompt, codex-run.sh / work-* command runs:
```bash
gh api "repos/${OWNER_REPO}/issues/${PR_NUMBER}/comments" \
  --jq '[.[] | select(.body | contains("<!-- relay:")) | .body] | join("\n\n---\n\n")' \
  > "$WT_PATH/work/items/$SLUG/pr-relay.md"
```

Fallback: skip if `gh` unavailable or no PR yet (relay.md local is sufficient).

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
- `work/locks/merge.lock` — one merge-and-cleanup at a time (implemented via `lib/merge-lock.sh`, uses `flock`)

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
