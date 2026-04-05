---
name: worknote
description: >
  Work journal management — view, sync to Notion, review by period, and plan tasks.
  Triggers on: "worknote", "업무일지", "업무 기록", "오늘 뭐했", "작업 기록",
  "work note", "work log", "daily log", "what did I do".
---

# Worknote

Daily work journal: local markdown + Notion sync.

## Routing

Parse `$ARGUMENTS`:

| Input | Action |
|-------|--------|
| (empty) / `today` | Read `~/.claude/worknote/YYYY-MM-DD.md` and display. If missing, say so. |
| `sync [date]` | Delegate to **worknote-sync** agent |
| `review <period> [flags]` | Delegate to **worknote-review** agent |
| `plan [period] [flags]` | Delegate to **worknote-plan** agent |

All subcommands except default view require Notion MCP (`mcp__notion__*`).

## Period & Scope (passed to agents as-is)

| Period | Meaning |
|--------|---------|
| `yesterday` | Previous day |
| `last-week` / `this-week` | Mon–Sun |
| `last-month` / `this-month` | Calendar month |
| `YYYY-MM` | Specific month |
| `YYYY-MM-DD..DD` | Date range |

| Scope Flag | Behavior |
|------------|----------|
| (default) | Current repo (`git rev-parse`) |
| `--project <name>` | Specific project |
| `--all` | All projects, grouped |
