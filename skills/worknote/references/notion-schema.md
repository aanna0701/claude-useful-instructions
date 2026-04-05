# Notion Work Journal DB Schema

- **DB ID**: `33963d5a-32cf-817d-a75c-000b886605dc`
- **Parent Page**: 업무일지 (`33963d5a-32cf-8019-95c6-cf0ff0828162`)
- **Title property**: `이름` (Korean)

## Properties

| Property | Type   | Description                |
|----------|--------|----------------------------|
| 이름     | title  | Work summary (one-line)    |
| Date     | date   | Filter/sort key            |
| Project  | select | Single repo/project name   |
| Status   | select | `draft` / `done` / `archived` |

One page per project per day. Upsert key: `Date` + `Project`.

## Page Body

```markdown
## Git Activity
- <hash> <commit message>

## Work Summary
- Key decisions and accomplishments

## Blockers
- (if any)

## Next
- [ ] Carry-over tasks
```

## Query Patterns

- Today + project: `Date` = today AND `Project` = value
- Range: `Date` between start..end
- All projects: omit `Project` filter
