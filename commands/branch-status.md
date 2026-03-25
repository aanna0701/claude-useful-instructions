# branch-status — Show Branch Map and Current State

Display the current branch hierarchy, working state, and optionally work item branch mappings.

Works standalone (single agent) or with the collab workflow.

---

## Input

**$ARGUMENTS**: Optional flags.
- No arguments: show full status
- `--brief`: one-line summary only

---

## Execution Steps

### Step 1: Read Branch Map

```bash
cat .claude/branch-map.yaml 2>/dev/null
```

If missing, auto-initialize by running `/branch-init` logic inline (detect branches, confirm with user, write config), then continue.

### Step 2: Current Branch State

```bash
git branch --show-current
git log --oneline -1
```

Determine:
- Current branch name
- Whether it's in the trunk chain or a feature branch
- Parent branch (from trunk_chain)

### Step 3: Freshness Check

Compare current branch against its parent:

```bash
git rev-list --left-right --count <parent>...<current>
```

Report:
- **Fresh**: current branch includes all parent commits
- **Behind by N commits**: needs rebase/merge from parent
- **Ahead by N commits**: has N commits ready to merge

### Step 4: Work Items (if collab workflow active)

If `work/items/` exists:

```bash
ls work/items/ 2>/dev/null
```

For each work item, extract from contract.md:
- Branch Map metadata (parent_branch, merge_target) if present
- Status from status.md

### Step 5: Print Summary

Print: trunk chain, working parent, current branch, parent, freshness (behind/ahead counts), and work items table (if any).

`--brief` format: `branch-map: main→develop→research | current: feat/FEAT-014 | fresh | 3 ahead`
