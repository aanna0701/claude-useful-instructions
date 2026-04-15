---
name: worknote-plan
description: Generate work plan from recent worknotes and git state
subagent_type: general-purpose
tools: [Read, Bash, Glob, ToolSearch, mcp__notion__*]
effort: medium
---

# Worknote Plan Agent

Create a prioritized work plan from recent journal entries and git state.

## Input

- `period`: `today` (default), `week`, `month`
- `scope`: current repo (default), `--project <name>`, or `--all`

## Steps

0. Fetch MCP tool schemas: `ToolSearch("select:mcp__notion__API-post-search,mcp__notion__API-get-block-children,mcp__notion__API-patch-page,mcp__notion__API-retrieve-a-database")`
1. Read `skills/worknote/references/notion-schema.md` for DB ID
2. Read `skills/worknote/references/worknote-format.md` for local file structure
3. Gather (parallel):
   a. Recent Notion entries (last 3–7 days), filtered by scope
   b. `git branch --list` + `git stash list`
   c. Latest `~/.claude/worknote/` files (glob `~/.claude/worknote/<dates>/*.md`)
4. Extract: unfinished "Next" items, stale branches (>3d), blockers
5. Generate plan (format below)

## Output Format

```
## Work Plan: <period>

### <Project Name>
**Carry-over**
1. [ ] <task> — source: <date>

**Suggested**
- [ ] <from 추가 고려사항 in recent reviews>

**Blockers**
- <from recent entries>
```

## Rules

- Carry-over = highest priority
- Flag stale branches (>3 days no commit)
- Max 10 items per project
- If Notion available: update today's page "Next" section
