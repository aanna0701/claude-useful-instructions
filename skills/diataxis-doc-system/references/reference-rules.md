# Reference Writing Rules

Rules that `doc-writer-reference` agent must Read before writing.

## Identity

Reference = document for **Information lookup**.
Reader wants **precise facts** — parameters, types, defaults, error codes.
Not teaching (Tutorial), problem-solving (How-to), or explaining rationale (Explanation).

## DO / DON'T

| DO | DON'T |
|----|-------|
| Describe **accurately and completely** | Mix in subjective judgment |
| Maintain **consistent structure** | Use different formats per item |
| Make it **searchable** | Write in flowing prose |
| Keep **in sync** with code | Copy-paste manually and forget |
| Always state **defaults and types** | Say "refer to the source" |

## Template: API Reference

```markdown
# [Service/Module] API Reference

> Version: [v1.2.3] | Last updated: [Date] | [Source code link]

## Authentication
| Method | Header | Format |
|--------|--------|--------|
| Bearer Token | `Authorization` | `Bearer <token>` |

## Endpoints

## # `POST /api/v1/resources`
[One-sentence description]

**Request**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | `string` | ✅ | — | Resource name (1-128 chars) |
| `type` | `enum` | ✅ | — | `"A"` \| `"B"` \| `"C"` |
| `limit` | `integer` | — | `100` | Max results (1-1000) |

**Response** `200 OK`
\```json
{
  "id": "res_abc123",
  "name": "example",
  "created_at": "2025-01-15T09:30:00Z"
}
\```

**Errors**
| Code | Meaning | Cause |
|------|---------|-------|
| `400` | Bad Request | Missing required field |
| `401` | Unauthorized | Token expired |
| `429` | Rate Limited | Per-minute limit exceeded |
```

## Template: Config Reference

```markdown
# [System] Configuration Reference

> Applies to: [version] | Config file: `config.yaml`

## Environment Variables
| Variable | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `DATABASE_URL` | `string` | — | ✅ | PostgreSQL connection string |
| `LOG_LEVEL` | `enum` | `"info"` | — | `"debug"` \| `"info"` \| `"warn"` \| `"error"` |
```

## Template: CLI Reference

```markdown
# [Tool] CLI Reference

## Global Options
| Option | Short | Type | Default | Description |
|--------|-------|------|---------|-------------|
| `--config` | `-c` | `path` | `~/.config/tool.yaml` | Config file path |
| `--verbose` | `-v` | `flag` | `false` | Verbose output |

## Commands

## # `tool create <name>`
[Description]

| Arg/Option | Type | Required | Description |
|------------|------|----------|-------------|
| `<name>` | `string` | ✅ | Resource name |
| `--dry-run` | `flag` | — | Preview only |

**Example:**
\```bash
tool create my-service --dry-run
\```
```

## Core Rules

## # 1. Consistency Is Everything
- Every item uses the **same structure**. One inconsistency erodes trust in the whole doc.

## # 2. Tables First
- Parameters, options, error codes -> **tables**, not prose.
- Required columns: `Name`, `Type`, `Required`, `Default`, `Description`.
- Description must include **constraints** (range, length, pattern).

## # 3. Defaults and Types Are Mandatory
- No default -> `—`. Never blank. Types match code: `string`, `integer`, `boolean`, `enum`.
- Enums: list all possible values.

## # 4. Examples: Minimal
- At least **1 example** per endpoint/command, simplest form only.
- Complex usage -> separate How-to Guide.

## # 5. Version and Date
- Header: **target version + last updated date**. Use `Added in v1.3` / `Deprecated in v2.0` badges.

## # 6. Code Sync
- Prefer **auto-generated** References (JSDoc, OpenAPI, TypeDoc).
- Manual docs: add "Update Reference" to PR checklist.

## Tone & Style

- Dry, factual, no emotional language. Third person or passive voice.
- "We recommend" and "usually" are forbidden -> move to How-to.

## Anti-Patterns

1. **"Narrative"**: 3-line backstory per parameter
2. **"Incomplete"**: 7 of 10 endpoints documented (all or nothing)
3. **"Inconsistent"**: A uses tables, B uses prose, C uses code comments
4. **"Snapshot"**: Accurate only at time of writing, no sync mechanism
