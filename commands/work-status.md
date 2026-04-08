# work-status — Check Work Item Progress

## Input

**$ARGUMENTS**: Optional work item ID (e.g., `FEAT-001`).

## CRITICAL: Worktree-First Gate

**Before reading ANY `status.md`**, you MUST resolve its worktree path. The main repo copy is a stale seed — it does NOT reflect Codex/agent progress.

❌ WRONG: `Read work/items/FEAT-001-foo/status.md` (cwd — stale, shows `open` even when done)
✅ RIGHT: Resolve worktree path FIRST → `Read /abs/path/to/worktree/work/items/FEAT-001-foo/status.md`

## Worktree Discovery (critical)

Work items live in worktrees, NOT the main repo. Discovery order:

1. Run `git worktree list` from cwd (or `$REPO_ROOT`)
2. For each worktree path, glob `{WT_PATH}/work/items/*/status.md`
3. Also glob `work/items/*/status.md` in the main repo (items not yet dispatched)
4. Deduplicate by item ID (worktree copy wins over main repo copy)

If cwd is not a git repo, scan `$ARGUMENTS` parent directory or ask user for repo path.

### Worktree search fallback

If `git worktree list` returns only the main repo (no worktrees), also scan sibling directories matching the naming convention:

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
PROJECT="$(basename "$REPO_ROOT")"
PARENT="$(dirname "$REPO_ROOT")"
# Scan: ${PARENT}/${PROJECT}-*/work/items/*/status.md
```

This catches worktrees created by other sessions or tools.

## Mode A: All Items (no argument)

Discover all items per § Worktree Discovery above. For each `status.md`, extract fields. Print table:

| ID | Title | Type | Status | Agent | Branch | Worktree | PR | Freshness |

Worktree column = absolute path from `status.md` `Worktree Path` field.

If no items: "No work items found. Use `/work-plan` to create one."

## Mode B: Specific Item

1. Find item by ID: search worktrees first (§ Worktree Discovery), then main repo
2. Read from worktree copy (authoritative per `rules/collab-workflow.md` § Worktree Rules)
3. Show detailed view: type, status, agent, branch, PR, progress (checklist), review decision, blockers
4. Surface `needs-sync` explicitly as preflight failure

## Next Actions

Print per-status commands:

**MANDATORY NEXT-STEP TEMPLATE** — Print only the line matching the item's status. Fill `«___»` slots with actual values.

```
📋 다음 단계
  planned          → /work-scaffold «ID» then bash codex-run.sh «ID»
  ready-for-review → /work-verify «ID» then /work-review «ID»
  revising         → bash codex-run.sh «ID» then /work-verify «ID» then /work-review «ID»
  implementing     → tail -f work/.dispatch-logs/«SLUG».log
  blocked          → git -C «WT_PATH» status --short, then bash codex-run.sh «ID»
```

Fallback: scaffold `--claude`, verify `--claude`, impl `/work-impl`.
`{WT_PATH}` = status.md Worktree Path (절대경로).
