# work-plan — Create Work Items for Delegation

Split topics into parallelizable work items with contract boundaries for Codex/Claude dispatch.

## Input

**$ARGUMENTS**: Feature topics (newline-separated) or path to source RFC/ADR.

```
/work-plan DuckDB schema cleanup
/work-plan --type=chore Dependency upgrade
```

## Work Types

| Type | ID Prefix | Branch Prefix | Commit Prefix |
|------|-----------|---------------|---------------|
| feat | `FEAT-NNN` | `feat/` | `feat` |
| fix | `FIX-NNN` | `fix/` | `fix` |
| docs | `DOCS-NNN` | `docs/` | `docs` |
| chore | `CHORE-NNN` | `chore/` | `chore` |
| refactor | `REFAC-NNN` | `refactor/` | `refactor` |
| test | `TEST-NNN` | `test/` | `test` |
| perf | `PERF-NNN` | `perf/` | `perf` |
| audit | `AUDIT-NNN` | `audit/` | `audit` |

Type resolution: explicit `--type=` > infer from keywords > ask user.
Audit keywords: "감사", "검증", "정합성", "audit", "check", "consistency", "convention".

## Execution Steps

### Step 1: Gather Context

Read `$ARGUMENTS` (file or topic). For each: Objective, Source, Scope (in/out), Boundaries.

### Step 2: Resolve Branch Map

Per `rules/branch-map-policy.md`. Read `.claude/branch-map.yaml`: `working_parent`, `default_merge_target`, `branch_prefixes`, `roles`. Default to `main` if absent.

### Step 3: Preflight

Acquire `work/locks/planning.lock`. Verify current branch = `working_parent`, worktree clean. Refuse if another planning run active.

### Step 4: Decompose

Find independent units (disjoint files, no runtime deps, testable in isolation). Don't split if < 3 files or tightly coupled.

### Step 5: Assign IDs

```bash
ls work/items/ 2>/dev/null | grep -oP '\w+-\K\d+' | sort -n | tail -1
```

Sequential `{TYPE}-NNN` (3-digit, zero-padded). Slug: kebab-case, max 30 chars.

### Step 6: Generate Work Items (parallel)

Spawn agents per item. Each generates `brief.md`, `contract.md`, `checklist.md`, `status.md` from templates. Ensure Allowed Modifications are **disjoint** across siblings.

**AUDIT variation**: "Allowed Modifications" → "Audit Scope", "Forbidden Zones" → "Out of Scope", "Interfaces" → "Audit Criteria", "Test Requirements" → "Expected Output Format".

### Step 7: Boundary Overlap Check

Always when 2+ items exist. Extract Allowed Modifications, check path overlaps. Print matrix. If overlaps: suggest narrowing, ask confirmation.

### Step 8: Create Worktrees & Branches

Per `rules/collab-workflow.md` § Worktree Rules (Creation):

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
PROJECT=$(basename "$REPO_ROOT")
SLUG="{TYPE}-NNN-slug"
BRANCH="${TYPE_PREFIX}${SLUG}"
WT_PATH="$(dirname "$REPO_ROOT")/${PROJECT}-${SLUG}"

git branch "$BRANCH" "$PARENT"
git worktree add "$WT_PATH" "$BRANCH"
```

Seed artifacts into worktree, commit. Update `status.md` with absolute `Worktree Path`.

### Step 9: GitHub Issues + Batch Manifest

Spawn `issue-creator` agent per item (parallel). Write `work/batches/{batch_id}.json`. Release planning lock.

### Step 10: Summary

Print table with absolute worktree paths, then next-step commands:

```
📋 다음 단계
  /work-scaffold {IDs}              # Cursor 없으면: --claude
  bash codex-run.sh {IDs}           # Codex 없으면: /work-impl {ID}
  /work-verify AUDIT-NNN            # AUDIT only
```
