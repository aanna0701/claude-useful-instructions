# Notion Work Journal DB Schema

- **DB ID**: `33963d5a-32cf-817d-a75c-000b886605dc`
- **Parent Page**: 업무일지 (`33963d5a-32cf-8019-95c6-cf0ff0828162`)
- **Title property**: `이름` (= project/repo name)

## Properties

| Property | Type   | Description                    |
|----------|--------|--------------------------------|
| 이름     | title  | Project/repo name (= identity) |
| Date     | date   | Filter/sort key                |
| Status   | select | `draft` / `done` / `archived`  |

One page per project per day. Upsert key: `Date` + `이름` (title).

## Page Body — Fixed Template

Section headings are **fixed strings**. Never rename, reorder, or invent new ones.
Omit a section only when its data source is empty.

| # | Heading (exact) | Block type | Data source | Required |
|---|----------------|------------|-------------|----------|
| 1 | `Work Summary` | heading_2 + bulleted_list_item | Synthesized work streams | always |
| 2 | `Git Activity` | heading_2 + bulleted_list_item | Commits section | if commits exist |
| 3 | `Changed Files` | heading_2 + bulleted_list_item | Staged/Changed section | if changes exist |
| 4 | `Next` | heading_2 + bulleted_list_item | Inferred carry-over, follow-ups | always |

Rules:
- Never use other heading names (Summary, Key Changes, Work Items, Files Changed, etc.)
- Never put `##` inside a paragraph block — use heading_2 blocks
- Never dump raw `git diff --stat` (e.g. `file.md | 2 +-`) — describe what changed

## Query Patterns

- Today + project: `Date` = today AND `이름` = repo name
- Range: `Date` between start..end
- All projects: omit `이름` filter
