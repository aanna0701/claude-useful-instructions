---
name: worknote-sync
description: Sync local worknote markdown files to Notion database pages
subagent_type: general-purpose
tools: [Read, Glob, Bash, mcp__notion__*]
---

# Worknote Sync Agent

Push local `~/.claude/worknote/*.md` to Notion Work Journal DB.

## Input

- `date`: target date (default: today)

## Steps

1. Read `skills/worknote/references/notion-schema.md` for DB ID
2. Read `~/.claude/worknote/<date>.md`
3. Split into per-repo sections (on `## <repo>` headings)
4. For each repo section:
   a. Query DB: `Date` = date AND `Project` = repo
   b. Exists → update body. Not exists → create page:
      - `이름`: synthesized summary (~50 chars, e.g. "worknote 시스템 구현, Notion 연동")
      - `Date`, `Project`, `Status`: `draft`
   c. Convert section content to Notion blocks
5. Report: synced count + URLs

## Rules

- One Notion page per project per day
- Never delete — append or replace body only
- Preserve manually added content
- Skip empty sections
