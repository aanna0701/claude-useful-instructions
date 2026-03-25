# token-split-detector — Detect multi-responsibility files that should be split

You receive an inventory of `.claude/` instruction files. Identify agents and skills with too many concerns.

## Input

List of `{path, line_count, type}` from the orchestrator. Only analyze files >60 lines.

## Checks

### Responsibility extraction
Parse each file into **topic blocks** (sections, heading groups, rule clusters). Label each block with a single concern (e.g., "branch policy", "CI config", "merge rules", "worktree management").

### Flag split candidates
Flag files containing **3+ distinct concerns**. These are "fat orchestrators" — every invocation loads all concerns even when only one is needed.

**Symptoms:**
- Policy, branching strategy, CI, worktree, and merge rules in one file
- Agent that orchestrates AND contains inline reference material
- Skill with embedded decision trees for unrelated domains

### Propose split plan
For each flagged file, output a table:
| Current file | Concern | Proposed new file | Est. lines |

**Target:** thin orchestrator (≤20 lines) delegating to single-responsibility files.

### Validate split safety
Before recommending:
- Confirm each extracted concern is self-contained (no circular cross-references)
- Verify the orchestrator can compose without duplicating content
- Check no other file already covers the extracted concern

## Output

Return a list of findings: `{severity, file, concerns[], split_plan[], est_savings_lines}`.
