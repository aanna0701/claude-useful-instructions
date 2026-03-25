# work-status — Check Work Item Progress

Show the status of work items in the current project.

---

## Input

**$ARGUMENTS**: Optional work item ID (e.g., `FEAT-001`).

---

## Execution

### Mode A: All Items (no argument)

Glob `work/items/FEAT-*/status.md`. For each, extract frontmatter and key fields.

Print summary table:

| ID | Title | Status | Agent | Branch | Merge Target | Freshness |
|----|-------|--------|-------|--------|--------------|-----------|
| FEAT-001 | User Auth | in-progress | Codex | feat/FEAT-001-user-auth | research | fresh |
| FEAT-002 | Cache Layer | open | TBD | — | research | — |

If `.claude/branch-map.yaml` exists, populate Merge Target from each contract's Branch Map section and check freshness against the declared parent branch.

If no work items found: "No work items found. Use `/work-plan` to create one."

### Mode B: Specific Item (FEAT-NNN given)

Resolve to directory under `work/items/`.

Read `status.md` and `checklist.md` in parallel.

Print detailed view:

```
FEAT-NNN: [Title]
Status:     in-progress
Agent:      Codex
Branch:     feat/FEAT-NNN-slug

Progress:   7/10 checklist items complete
  [x] Item 1
  [x] Item 2
  [ ] Item 3 (pending)
  ...

Blockers:   None
Ambiguities: None

Changed Files:
  src/auth/handler.go — new auth middleware
  src/auth/handler_test.go — unit tests
```

If `review.md` exists, append:
```
Review:     REVISE (2 items remaining)
```

### Always: Print Next Actions

After the table (Mode A) or detail view (Mode B), print actionable commands based on each item's status:

```
Next Actions
──────────────────────────────────────────────
# open → dispatch to Codex
  bash codex-run.sh FEAT-001 FEAT-002
  # or per item:
  codex exec --full-auto --cd <worktree_path> "Implement FEAT-001. Read work/items/FEAT-001-slug/contract.md and follow AGENTS.md."

# done → review
  /work-review FEAT-003

# revision → re-dispatch
  /work-revise FEAT-004
  # or direct:
  codex exec --full-auto --cd <worktree_path> "Revise FEAT-004. Read work/items/FEAT-004-slug/review.md for MUST-fix items, then contract.md. Follow AGENTS.md."

# in-progress → check logs
  tail -f work/.dispatch-logs/FEAT-005-slug.log
──────────────────────────────────────────────
```

Only print sections that have matching items. Always include the actual `codex exec` command with `--cd <worktree_path>` resolved from each item's `status.md`.
