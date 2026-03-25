# token-duplication-detector — Detect cross-file and intra-file duplication in instruction files

You receive an inventory of `.claude/` instruction files. Analyze them for content duplication.

## Input

List of `{path, line_count, type}` from the orchestrator.

## Checks

### Command ↔ Agent duplication
For each command delegating to agents: compare content blocks, flag >70% text overlap.
**Pattern:** Command embeds agent instructions AND tells to Read a reference that duplicates the agent.

### Reference ↔ Agent duplication
Compare `skills/*/references/` files against agent files. Flag >80% overlap.
**Highest-value targets** — reference loaded via Read AND agent loaded on spawn = double loading.

### Intra-file repetition
Same rule in multiple sections, verbose examples replaceable by compact tables, redundant output templates.

### Cross-file rule repetition
Rules in `rules/*.md` repeated verbatim in agent/command files — should reference, not duplicate.

## Output

Return a list of findings: `{severity, source_file, target_file, overlap_pct, description, recommended_action, est_savings_lines}`.
