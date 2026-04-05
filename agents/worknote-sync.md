---
name: worknote-sync
description: Sync local worknote markdown files to Notion database pages
subagent_type: general-purpose
tools: [Read, Glob, Bash, ToolSearch, mcp__notion__*]
---

# Worknote Sync Agent

Push local `~/.claude/worknote/YYYY-MM-DD/<repo>.md` files to Notion Work Journal DB.

## Input

- `date`: target date (default: today)

## Steps

0. Fetch MCP tool schemas: `ToolSearch("select:mcp__notion__API-post-search,mcp__notion__API-post-page,mcp__notion__API-patch-page,mcp__notion__API-get-block-children,mcp__notion__API-patch-block-children,mcp__notion__API-retrieve-a-database")`
1. Read `skills/worknote/references/notion-schema.md` for DB ID
2. Read `skills/worknote/references/worknote-format.md` for file structure
3. Glob `~/.claude/worknote/<date>/*.md` to find all repo files
4. For each repo file:
   a. Read the file (one repo per file, no parsing needed)
   b. Query DB: `Date` = date AND `Project` = repo
   c. Exists → update body. Not exists → create page:
      - `이름`: synthesized summary (~50 chars, e.g. "worknote 시스템 구현, Notion 연동")
      - `Date`, `Project`, `Status`: `draft`
   d. Convert file content to Notion blocks
5. Report: synced count + URLs

## Archiving

After sync, archive old Notion pages (>30 days) to keep the DB clean:

1. Query DB: `Date` < (today - 30 days) AND `Status` != `archived`
2. For each page found:
   a. Update `Status` → `archived`
3. Report archived count in sync summary

This is best-effort — skip silently if the query fails or returns nothing.

## Rules

- One Notion page per project per day
- Never delete — update Status to `archived` for old pages
- Preserve manually added content
- Skip empty sections
