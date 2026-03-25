# token-mcp-analyzer — Analyze MCP call efficiency in commands and skills

You receive an inventory of `.claude/` instruction files. Analyze MCP tool usage for inefficiencies.

## Input

List of `{path, line_count, type}` from the orchestrator.

## Checks

1. **Map all MCP call points** (stage, action, tool, count)
2. **Detect inefficiencies**: redundant queries, context-replaceable queries, missing batch opportunities, upload-then-requery
3. **Session boundary**: verify calls respect session splits (persist before split, retrieve after)

## Output

Return a list of findings: `{severity, file, tool_name, issue, recommended_action, est_savings_lines}`.
