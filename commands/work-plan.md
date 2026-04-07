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
| audit | `AUDIT-NNN` | `audit/` | `audit` | Code audit, consistency check |

**Type resolution order**: explicit `--type=` flag > infer from topic keywords > ask user.

**Audit keyword detection**: "감사", "검증", "정합성", "audit", "check", "consistency", "convention", "code review" → `--type=audit`

---

## Execution Steps

### Step 1: Gather Context

If `$ARGUMENTS` is a file path, read it. For each topic gather: Objective, Source (RFC/ADR path), Scope (in/out), Boundaries (files/modules).

### Step 1.5: Resolve Branch Map

Per `rules/branch-map-policy.md`. Read `.claude/branch-map.yaml` and extract:
- `working_parent`
- `default_merge_target`
- `branch_prefixes`
- `roles`

Single-branch projects default to `main` if no branch map exists.

### Step 1.6: Preflight Safety

Before creating anything:
- Acquire `work/locks/planning.lock`
- Verify the current branch equals `working_parent`
- Verify the `working_parent` worktree is clean except for intentional planning files
- Refuse to continue if another planning run appears active

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

**AUDIT type contract variation**: Use alternative section names:
- "Allowed Modifications" → "Audit Scope" (files/directories to audit)
- "Forbidden Zones" → "Out of Scope"
- "Interfaces" → "Audit Criteria" (what to check)
- "Test Requirements" → "Expected Output Format" (report structure)
- "Invariants" → kept as-is (rules/standards to check against)

Write to `work/items/{TYPE}-NNN-slug/`.

### Step 5: Boundary Overlap Check

**Always run when 2+ items exist** (including previously open items).

Extract "Allowed Modifications" from each contract. Check all pairs for path overlap (directory contains file = overlap). Print boundary matrix (independent / overlap / dependency).

If overlaps found: print conflicts, suggest narrowing or merging, ask user to confirm.

### Step 6: Create Worktrees & Branches

```bash
PROJECT=$(basename "$(git rev-parse --show-toplevel)")
PARENT=<working_parent>
TYPE_PREFIX=<branch_prefixes[type]>
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
git -C "$WT_PATH" add -f "$FEAT_DIR/" AGENTS.md
git -C "$WT_PATH" commit -m "chore($SLUG): seed work item artifacts"
```

Update `status.md`:
- `Status = planned`
- Branch
- Worktree
- Worktree Path
- Batch ID

### Step 7: Create GitHub Issues

Spawn `issue-creator` agent per item (parallel). Creates GitHub Issue from brief + contract + checklist, records issue number in `status.md`. Skip silently if `gh` unavailable.

### Step 8: Generate Batch Manifest

Write the canonical manifest to `work/batches/{batch_id}.json`:
- `batch_id`
- `created`
- `working_parent`
- `items[]`
- `parallel_groups[]`

Optionally refresh `work/dispatch.json` as a latest-batch pointer or mirror.

### Step 8.5: Release Planning Lock

Always release `work/locks/planning.lock`, even on failure.

### Step 9: Summary

Print summary table, then **type-aware next steps**:

```
Work Plan Ready
──────────────────────────────────────────────
  FEAT-001   schema-cleanup   #42  ../project-FEAT-001-schema-cleanup
  REFAC-002  split-logger     #43  ../project-REFAC-002-split-logger
  AUDIT-003  naming-check     #44  ../project-AUDIT-003-naming-check
──────────────────────────────────────────────
Batch: work/batches/2026-04-03-schema-cleanup.json

Next Steps — by type:
──────────────────────────────────────────────
# FEAT / REFAC — Scaffold with Cursor/Antigravity, then dispatch to Codex
/work-scaffold FEAT-001 REFAC-002
bash codex-run.sh FEAT-001 REFAC-002

# AUDIT — Verify directly with Cursor/Antigravity (no Codex needed)
/work-verify AUDIT-003

# Or skip Cursor/Antigravity — dispatch directly
bash codex-run.sh FEAT-001 REFAC-002

# Single item via Claude
/work-impl FEAT-001
──────────────────────────────────────────────
```
