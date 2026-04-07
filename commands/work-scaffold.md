# work-scaffold — Generate Cursor Composer Prompts from Contracts

Generate Cursor Composer prompts for scaffolding file structures. Type is auto-detected from work item ID prefix.

---

## Input

**$ARGUMENTS**: Work item IDs (space-separated).

```
/work-scaffold FEAT-001
/work-scaffold FEAT-001 REFAC-002
/work-scaffold AUDIT-003          # → prints skip message
```

---

## Type → Behavior Matrix

| Type Prefix | Action | Template Used |
|-------------|--------|---------------|
| `FEAT`, `FIX`, `CHORE`, `PERF`, `TEST` | Generate file structure + type stubs | `scaffold-feat.md` |
| `REFAC` | Generate migration map + rename list | `scaffold-refactor.md` |
| `AUDIT`, `DOCS` | Skip — print redirect to `/work-verify` | _(none)_ |

---

## Execution Steps

### Step 1: Resolve Work Items

For each ID in `$ARGUMENTS`:

1. Locate `work/items/{ID}-*/` directory (glob match)
2. Read `status.md` — verify status is `planned` or `scaffolded`
3. Read worktree path from `status.md`
4. Extract type prefix from ID

### Step 2: Generate Prompts (parallel per item)

Spawn `cursor-prompt-builder` agent for each item with `mode=scaffold`.

The agent:
1. Parses `brief.md` and `contract.md`
2. Selects template based on type
3. Fills template variables
4. Returns rendered prompt + `.cursorrules` content

### Step 3: Generate .cursorrules

For each non-AUDIT item:

1. Write `.cursorrules` to the worktree root: `{worktree_path}/.cursorrules`
2. Stage and commit: `chore({SLUG}): add .cursorrules for Cursor integration`

### Step 4: Update Status

For each processed item:
- Update `status.md` → `Status = scaffolded`
- Update in both control plane (`work/items/`) and worktree

### Step 5: Output

Print each prompt in a fenced code block with copy instruction:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FEAT-001 — Cursor Composer Prompt
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

<rendered prompt here>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Copy the prompt above → Cursor Composer (Cmd+I / Ctrl+I)
🎯 Open worktree in Cursor: cursor {worktree_path}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

For AUDIT/DOCS items:
```
AUDIT-003 — Scaffold not needed for audit items.
Next: /work-verify AUDIT-003
```

After all items:
```
Next Steps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# After Cursor scaffolding, dispatch to Codex:
bash codex-run.sh {non-audit IDs}

# Or implement manually:
/work-impl {ID}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Error Handling

- Missing work item directory: `ERROR: {ID} not found in work/items/`
- Status not `planned`: `WARN: {ID} status is '{status}', expected 'planned'. Proceeding anyway.`
- Missing worktree: `WARN: Worktree not found at {path}. Printing prompt without .cursorrules generation.`
- AUDIT items are not errors — just redirects to `/work-verify`
