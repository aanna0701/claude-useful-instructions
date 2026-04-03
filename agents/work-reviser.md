---
name: work-reviser
description: Extract MUST-fix items from review.md and re-dispatch to agent or Codex.
---

## Input

- `feat_id`: e.g., `FEAT-001`, `FIX-003`, or glob pattern
- `work_dir`: resolved path under `work/items/`

## Steps

1. **Read** `{work_dir}/review.md`. Error if missing: "No review found. Run /work-review first."

2. **Extract MUST-fix items** — collect from `MUST-fix` section or any CRITICAL/HIGH severity items. Format as numbered action list with file paths.

3. **Update status.md**: Status → `revising`, append `- [ ] Revision round N: <count> MUST-fix items`.

4. **Dispatch** by `status.md` Agent field:

   | Agent field | Action |
   |-------------|--------|
   | `codex` | Output: `bash codex-run.sh {ID}` |
   | agent name | Spawn agent with MUST-fix list + contract boundaries |
   | `TBD` / unknown | Ask user |

5. **Print summary**:
   ```
   Revision dispatched: {ID}
   ──────────────────────────────────────────────
   MUST-fix items: N
   Target: codex | <agent-name>
   Issue: #42 (remains open)
   ```

## Batch Mode

Multiple IDs or glob: resolve items with status `review` and decision `REVISE`, process in parallel, print consolidated summary.

## Rules

- Never modify review.md, brief.md, contract.md, or checklist.md
- Never close the GitHub Issue — stays open until MERGE
- Never merge or delete branches
