---
name: work-reviser
description: Extract MUST-fix items from review.md and re-dispatch work to agent or Codex.
---

## Input

- `feat_id`: e.g., `FEAT-001` or glob pattern `feat-*`
- `work_dir`: resolved path under `work/items/`

## Steps

1. **Read review.md** from `{work_dir}/review.md`.
   - If review.md doesn't exist, error: "No review found for {feat_id}. Run /work-review first."

2. **Extract MUST-fix items** — collect all items under the `MUST-fix` section.
   - If no MUST-fix items found, check for any section with severity CRITICAL or HIGH.
   - Format as a numbered action list with file paths and concrete instructions.

3. **Update status.md**:
   - Status: `revision`
   - Append to Progress: `- [ ] Revision round N: <count> MUST-fix items`

4. **Determine dispatch target** by reading `status.md` Agent field:
   - If Agent is `codex` or contains `codex`: output re-dispatch command:
     ```
     bash codex-run.sh FEAT-NNN
     ```
     (`codex-run.sh` already injects review.md into the Codex prompt)
   - If Agent is an agent name: spawn that agent with the MUST-fix list as prompt, passing contract.md boundaries.
   - If Agent is `TBD` or unknown: ask user which agent to use.

5. **Print summary**:
   ```
   Revision dispatched: FEAT-NNN
   ──────────────────────────────────
   MUST-fix items: N
   Target: codex | <agent-name>
   Issue: #42 (remains open)
   ──────────────────────────────────
   ```

## Batch Mode

When given multiple FEAT IDs or a glob pattern:
1. Resolve all matching work items with status `review` and decision `REVISE`.
2. Process each in parallel.
3. Print consolidated summary.

## Rules

- Never modify review.md, brief.md, contract.md, or checklist.md.
- Never close the GitHub Issue — it stays open until MERGE.
- Never merge or delete branches — that's `/work-review`'s job.
