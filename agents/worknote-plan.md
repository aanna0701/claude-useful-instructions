---
name: worknote-plan
description: Generate work plan from recent worknotes and git state
subagent_type: general-purpose
tools: [Read, Bash, Glob, mcp__notion__*]
---

# Worknote Plan Agent

Create a prioritized work plan from recent journal entries and git state.

## Input

- `period`: `today` (default), `week`, `month`
- `scope`: current repo (default), `--project <name>`, or `--all`

## Steps

1. Read `skills/worknote/references/notion-schema.md` for DB ID
2. Gather (parallel):
   a. Recent Notion entries (last 3–7 days), filtered by scope
   b. `git branch --list` + `git stash list`
   c. Latest `~/.claude/worknote/` files
3. Extract: unfinished "Next" items, stale branches (>3d), blockers
4. Generate plan (format below)

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
