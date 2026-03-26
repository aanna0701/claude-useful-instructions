# work-plan — Create Work Items for Delegation

Split topics into parallelizable work items with contract boundaries for Codex/Claude dispatch.

---

## Input

**$ARGUMENTS**: Feature topics (newline-separated) or path to source RFC/ADR.

```
/work-plan DuckDB schema cleanup
/work-plan --type=chore Dependency upgrade
```

---

## Work Types

| Type | ID Prefix | Branch Prefix | Commit Prefix | When to Use |
|------|-----------|---------------|---------------|-------------|
| feat | `FEAT-NNN` | `feat/` | `feat` | New functionality |
| fix | `FIX-NNN` | `fix/` | `fix` | Bug fixes |
| docs | `DOCS-NNN` | `docs/` | `docs` | Documentation only |
| chore | `CHORE-NNN` | `chore/` | `chore` | Maintenance, deps |
| refactor | `REFAC-NNN` | `refactor/` | `refactor` | Code restructuring |
| test | `TEST-NNN` | `test/` | `test` | Test additions |
| perf | `PERF-NNN` | `perf/` | `perf` | Performance tuning |

**Type resolution order**: explicit `--type=` flag > infer from topic keywords > ask user.

---

## Execution Steps

### Step 1: Gather Context

If `$ARGUMENTS` is a file path, read it. For each topic gather: Objective, Source (RFC/ADR path), Scope (in/out), Boundaries (files/modules).

### Step 1.5: Resolve Branch Map

Per `rules/branch-map-policy.md` § Branch Selection. Read `.claude/branch-map.yaml` (auto-init via `/branch-init` if missing). Extract: `working_parent`, `default_merge_target`, `role`, `ci_scope`. Single-branch projects default to `main`/`master`.

### Step 2: Decompose into Parallel Sub-tasks

For each topic, find independent units (disjoint files, no runtime deps, testable in isolation).

Strategies: by module/table, by layer (if truly independent), by feature boundary.

**Don't split** if < 3 files total, tightly coupled, or user requests single item. If unsure, propose and confirm.

### Step 3: Assign IDs

```bash
ls work/items/ 2>/dev/null | grep -oP '\w+-\K\d+' | sort -n | tail -1
```

Sequential `{TYPE}-NNN` (3-digit, zero-padded). Slug: lowercase kebab-case, max 30 chars. Sibling items share a consistent prefix.

### Step 4: Generate Work Items (parallel)

Spawn parallel agents (one per item). Each generates `brief.md`, `contract.md`, `checklist.md`, `status.md` from `.claude/templates/work-item/`. Ensure Allowed Modifications are **disjoint** across siblings. Fill contract's "## Branch Map" section from Step 1.5.

Write to `work/items/{TYPE}-NNN-slug/`.

### Step 5: Boundary Overlap Check

**Always run when 2+ items exist** (including previously open items).

Extract "Allowed Modifications" from each contract. Check all pairs for path overlap (directory contains file = overlap). Print boundary matrix (independent / overlap / dependency).

If overlaps found: print conflicts, suggest narrowing or merging, ask user to confirm.

### Step 6: Create Worktrees & Branches

```bash
PROJECT=$(basename "$(git rev-parse --show-toplevel)")
PARENT=<working_parent>
TYPE_PREFIX=<branch prefix from Work Types table>
SLUG="{TYPE}-NNN-slug"
BRANCH="${TYPE_PREFIX}${SLUG}"
WT_PATH="../${PROJECT}-${SLUG}"

git branch "$BRANCH" "$PARENT"
git worktree add "$WT_PATH" "$BRANCH"

# Seed planning artifacts into worktree
BASE_REPO="$(git rev-parse --show-toplevel)"
FEAT_DIR="work/items/$SLUG"
mkdir -p "$WT_PATH/$FEAT_DIR"
cp "$BASE_REPO/$FEAT_DIR"/{brief,contract,checklist,status}.md "$WT_PATH/$FEAT_DIR/"
cp "$BASE_REPO/AGENTS.md" "$WT_PATH/AGENTS.md" 2>/dev/null || true
git -C "$WT_PATH" add "$FEAT_DIR/" AGENTS.md
git -C "$WT_PATH" commit -m "chore($SLUG): seed work item artifacts"
```

Update `status.md`: Branch, Worktree, Worktree Path (absolute).

### Step 7: Create GitHub Issues

Spawn `issue-creator` agent per item (parallel). Creates GitHub Issue from brief + contract + checklist, records issue number in `status.md`. Skip silently if `gh` unavailable.

### Step 8: Generate Dispatch Manifest

Create/update `work/dispatch.json`: `batch_id`, `created`, `parent_topic`, `items[]` ({id, slug, type, status, issue, worktree_path, depends_on, conflicts_with}), `parallel_groups[]`.

### Step 9: Summary

Print summary table, then **all dispatch options**:

```
Work Plan Ready
──────────────────────────────────────────────
  FEAT-001  schema-cleanup   #42  ../project-FEAT-001-schema-cleanup
  CHORE-002 dep-upgrade      #43  ../project-CHORE-002-dep-upgrade
──────────────────────────────────────────────

Next Steps — pick one:
──────────────────────────────────────────────
# Batch dispatch
bash codex-run.sh FEAT-001 CHORE-002

# Single item via Claude
/work-impl FEAT-001

# Direct codex exec (per item)
codex exec --full-auto --cd <worktree_path> \
  "Implement {ID}. Read work/items/{SLUG}/contract.md and follow AGENTS.md."
──────────────────────────────────────────────
```
