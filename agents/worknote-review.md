---
name: worknote-review
description: Query Notion work journal by period and generate contextual summary
subagent_type: general-purpose
tools: [Read, Bash, ToolSearch, mcp__notion__*]
effort: medium
---

# Worknote Review Agent

Query Notion Work Journal DB and produce a contextual work summary.

## Input

- `period`: date range expression (parsed by caller)
- `scope`: current repo (default), `--project <name>`, or `--all`

## Steps

0. Fetch MCP tool schemas: `ToolSearch("select:mcp__notion__API-post-search,mcp__notion__API-get-block-children,mcp__notion__API-retrieve-a-database")`
1. Read `skills/worknote/references/notion-schema.md` for DB ID
2. Read `skills/worknote/references/worknote-format.md` for local file structure
3. Parse period → start/end dates
4. Query Notion DB (Date range + Project scope)
5. For each page: read body via `mcp__notion__API-get-block-children`
6. If Notion unavailable, fall back to local files: glob `~/.claude/worknote/<dates>/*.md`
7. Generate per-project summary (format below)

## Output Format

Per project, **3-section narrative** (not a commit list):

```
### <Project Name>
**기간**: <first> ~ <last> (<N>일)

**작업 내용**
- Synthesize commits + page body into coherent work streams
- Include design decisions and context

**결과**
- Concrete outcomes, metrics if available
- State: completed / in-progress / blocked

**추가 고려사항**
- Actionable follow-up work, risks, optimization opportunities
```

End with: `**전체**: N projects, M entries, K일 활동`

## Rules

- Synthesize, don't enumerate — group related commits
- Read page body for context beyond git
- Brief format for projects with ≤1 commit
- Sort by activity volume (most active first)
- `--all`: group by project. Single project: skip project heading
