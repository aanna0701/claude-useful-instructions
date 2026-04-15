---
name: worknote-sync
description: Sync local worknote markdown files to Notion database pages
subagent_type: general-purpose
tools: [Read, Glob, Bash, ToolSearch, mcp__notion__*]
effort: low
---

# Worknote Sync Agent

Push local `~/.claude/worknote/YYYY-MM-DD/<repo>.md` files to Notion Work Journal DB.

## Input

- `date`: target date (default: today)

## Steps

0. Fetch MCP tool schemas: `ToolSearch("select:mcp__notion__API-post-page,mcp__notion__API-patch-page,mcp__notion__API-query-data-source,mcp__notion__API-get-block-children,mcp__notion__API-patch-block-children,mcp__notion__API-delete-a-block")`
1. Read `skills/worknote/references/notion-schema.md` for DB ID and property names
2. Read `skills/worknote/references/worknote-format.md` for local file structure
3. Glob `~/.claude/worknote/<date>/*.md` to find all repo files
4. For each repo file, execute Step A → Step B → Step C in order:

### Step A — Read and synthesize

Read the local file. It contains raw git data (commits, staged, changed sections).

**Title (`이름`)**: The repo/project name from the filename (e.g., `VasIntelli-research`, `claude-useful-instructions`). Title = project identity, not a summary.

**Body**: You MUST produce a JSON array of Notion blocks that follows the
fixed template below **exactly**. Do not invent sections, reorder them,
or rename headings. Only omit a section when its data source is empty.

```jsonc
[
  // ── 1. Work Summary (ALWAYS) ─────────────────────────────
  { "type": "heading_2", "heading_2": { "rich_text": [
      { "type": "text", "text": { "content": "Work Summary" }}
  ]}},
  // one bulleted_list_item per logical work stream (NOT per commit)
  { "type": "bulleted_list_item", "bulleted_list_item": { "rich_text": [
      { "type": "text", "text": { "content": "<작업 스트림 요약 — 관련 커밋 그룹화, 무엇을 왜 했는지>" }}
  ]}},

  // ── 2. Git Activity (ONLY when Commits section exists) ───
  { "type": "heading_2", "heading_2": { "rich_text": [
      { "type": "text", "text": { "content": "Git Activity" }}
  ]}},
  // one bulleted_list_item per commit, keep original hash+message
  { "type": "bulleted_list_item", "bulleted_list_item": { "rich_text": [
      { "type": "text", "text": { "content": "<hash> <commit message>" }}
  ]}},

  // ── 3. Changed Files (ONLY when Staged/Changed section exists) ──
  { "type": "heading_2", "heading_2": { "rich_text": [
      { "type": "text", "text": { "content": "Changed Files" }}
  ]}},
  // one bulleted_list_item per file/dir, human-readable description
  { "type": "bulleted_list_item", "bulleted_list_item": { "rich_text": [
      { "type": "text", "text": { "content": "<path> — <무엇이 바뀌었는지 설명>" }}
  ]}},

  // ── 4. Next (ALWAYS — infer from context) ────────────────
  { "type": "heading_2", "heading_2": { "rich_text": [
      { "type": "text", "text": { "content": "Next" }}
  ]}},
  // bulleted_list_item: carry-over tasks, follow-ups, things to verify
  { "type": "bulleted_list_item", "bulleted_list_item": { "rich_text": [
      { "type": "text", "text": { "content": "<다음에 할 일 / 검증 필요 사항 / carry-over>" }}
  ]}}
]
```

CRITICAL:
- Section headings are fixed strings: "Work Summary", "Git Activity", "Changed Files", "Next"
- NEVER use other heading names (Summary, Key Changes, Work Items, Files Changed, etc.)
- NEVER dump raw git stat (`file.md | 2 +-`, `3 files changed, ...`)
- NEVER put `##` inside a paragraph block — use heading_2 blocks
- If only Staged/Changed (no commits), write "Work in Progress" in Work Summary

### Step B — Upsert page (CRITICAL: query before create)

Query the DB to check if a page already exists for this (date, title) pair:

```
mcp__notion__API-query-data-source({
  data_source_id: "<DB_ID>",
  filter: {
    "and": [
      { "property": "Date", "date": { "equals": "<date>" } },
      { "property": "이름", "title": { "equals": "<repo>" } }
    ]
  }
})
```

- **If results exist** → use `mcp__notion__API-patch-page` on the FIRST result's ID.
  Then delete all existing child blocks and re-create body blocks.
- **If no results** → use `mcp__notion__API-post-page` to create a new page with:
  - `이름`: repo name (e.g., "VasIntelli-research")
  - `Date`: { "start": "<date>" }
  - `Status`: { "name": "draft" }

Do NOT skip the query step. Creating without querying causes duplicate pages.

### Step C — Write body blocks

Pass the JSON array from Step A directly to `mcp__notion__API-patch-block-children`.
Do not restructure, rename, or reorder — the template is the source of truth.

5. Report: synced count + Notion page URLs (clickable)

## Archiving

After sync, archive old Notion pages (>30 days) to keep the DB clean:

1. Query DB: `Date` before (today - 30 days) AND `Status` does not equal `archived`
2. For each page found: update `Status` → `archived` via `patch-page`
3. Report archived count in sync summary

This is best-effort — skip silently if the query fails or returns nothing.

## Rules

- **One Notion page per project per day** — always query before create
- Title = project/repo name (not a work summary)
- Never delete pages — update Status to `archived` for old pages
- Never dump raw git stat output — always synthesize into readable content
- Skip empty sections
