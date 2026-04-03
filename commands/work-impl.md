# work-impl — Implement a Work Item in Its Worktree

Resolve a work item or GitHub Issue to its worktree and implement per contract.

---

## Input

**$ARGUMENTS**: Issue number (`#42`), work item ID (`FEAT-001`, `FIX-003`), or `all` (all planned/revising items).

No arguments: list `planned` and `revising` work items and ask which to implement.

---

## Execution

### Step 1: Resolve to Work Item

- `#42` → scan `work/items/*/status.md` for matching Issue field
- `FEAT-001` → find `work/items/FEAT-001-*/`
- `all` → find items with status `planned` or `revising`

Error if not found: "No work item found for {arg}. Run /work-plan first."

### Step 2: Read Context & Switch to Worktree (parallel)

Read contract.md, checklist.md, status.md, review.md (if `revising`) from the work item directory.

Use `Worktree Path` from status.md. Verify via `git worktree list`; recreate if missing. **All subsequent operations run in the worktree.**

The `working_parent` branch is orchestration-only. Never implement there.

### Step 3: Sync Preflight

Preferred path: run via `codex-run.sh`, which auto-syncs the worktree branch from the contract parent branch before Codex starts.

If the repo has `pyproject.toml` and `uv.lock`, the preferred path also runs `uv sync --frozen` before implementation. Treat Python dependency setup as a preflight concern, not something Codex improvises during implementation.

If running manually, from contract's "## Branch Map", verify feature branch is based on declared parent:
```bash
git merge-base --is-ancestor "<parent_branch>" HEAD
```

If the branch is still stale after runner sync, or if manual verification fails: set status to `blocked` with `needs-sync`.

If dependency outputs from earlier items are missing, also `needs-sync` — never recreate moved files or violate boundaries.

If Python dependencies are missing and the project uses uv: set status to `blocked` with `env-setup` unless the runner preflight resolves it.

### Step 4: Implement

Acquire `work/locks/{ID}.lock`.

Update status.md:
- `Status -> implementing`
- `Agent -> current identity`

Follow contract strictly: only Allowed Modifications, never Forbidden Zones, satisfy Test Requirements, preserve Invariants. If `revising`, resolve all MUST-fix from review.md first. Record ambiguities in status.md (never resolve unilaterally).

### Step 5: Complete & Push

Update status.md:
- `Status -> ready-for-review`
- Changed Files
- Verification
- Doc Changes Needed

**Gitignore note**: Target projects may gitignore `work/`. Always use `git add -f` for files under `work/items/`:
```bash
git add -f "work/items/${SLUG}/"
git add -A   # for non-work files
```

Commit with `{commit_prefix}({ID}): <description>` (prefix from Work Types table in `/work-plan`), push with `-u`.

Create draft PR:
```bash
MERGE_TARGET=<from contract Branch Map>
ISSUE=<from status.md>

gh pr create \
  --base "$MERGE_TARGET" \
  --head "<branch>" \
  --title "{ID}: <title from brief>" \
  --body "## Objective
<from brief.md>

## Changed Files
<from status.md>

## Checklist
<checked items from checklist.md>

---
Closes #${ISSUE}
Work item: \`work/items/{SLUG}/\`" \
  --draft
```

Update status.md with PR field. If `gh` fails, warn and continue.

Release `work/locks/{ID}.lock`.

Print: ID, issue, branch, PR (draft), status `ready-for-review`, next command `/work-review {ID}`.
