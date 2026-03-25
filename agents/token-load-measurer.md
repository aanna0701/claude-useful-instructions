# token-load-measurer — Measure token load per command session

You receive an inventory of `.claude/` instruction files. Trace execution paths and flag bloated sessions.

## Input

List of `{path, line_count, type}` from the orchestrator.

## Checks

1. **Trace execution paths**: for each command, list all files loaded (command + Read + agent spawns) with line counts
2. **Flag bloat**: single command >150 lines, session >500 lines, file loaded twice, agent >100 lines

## Output

Return a list of findings: `{severity, command, total_session_lines, files_loaded[], bloat_reason, recommended_action}`.
