# work-plan — Create Work Items for Delegation

Split topics into parallelizable work items with contract boundaries for Codex/Claude dispatch.

## Input

**$ARGUMENTS**: Feature topics (newline-separated) or path to source RFC/ADR.

```
/work-plan DuckDB schema cleanup
/work-plan --type=chore Dependency upgrade
```

## Work Types

| Type | ID Prefix | Branch Pattern | Commit Prefix |
|------|-----------|----------------|---------------|
| feat | `FEAT-NNN` | `feature-{slug}` | `feat` |
| fix | `FIX-NNN` | `feature-fix-{slug}` | `fix` |
| docs | `DOCS-NNN` | `feature-docs-{slug}` | `docs` |
| chore | `CHORE-NNN` | `feature-chore-{slug}` | `chore` |
| refactor | `REFAC-NNN` | `feature-refac-{slug}` | `refactor` |
| test | `TEST-NNN` | `feature-test-{slug}` | `test` |
| perf | `PERF-NNN` | `feature-perf-{slug}` | `perf` |
| audit | `AUDIT-NNN` | `feature-audit-{slug}` | `audit` |

**Branch naming rule:** All branches start with `feature-`. For `feat` type, use `feature-{slug}` directly. For all other types, use `feature-{type}-{slug}`.

Type resolution: explicit `--type=` > infer from keywords > ask user.
Audit keywords: "감사", "검증", "정합성", "audit", "check", "consistency", "convention".

## Execution Steps

### Step 1: Gather Context

Read `$ARGUMENTS` (file or topic). For each: Objective, Source, Scope (in/out), Boundaries.

### Step 2: Resolve Base Branch

Use the **current branch** as the base for all worktrees. No branch-map needed.

```bash
BASE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
```

### Step 3: Preflight

Acquire `work/locks/planning.lock`. Verify worktree clean. Refuse if another planning run active.

### Step 4: Decompose

Find independent units (disjoint files, no runtime deps, testable in isolation). Don't split if < 3 files or tightly coupled.

### Step 5: Assign IDs

```bash
ls work/items/ 2>/dev/null | grep -oP '\w+-\K\d+' | sort -n | tail -1
```

Sequential `{TYPE}-NNN` (3-digit, zero-padded). Slug: kebab-case, max 30 chars.

### Step 6: Generate Work Items (parallel)

Spawn agents per item. Each generates `brief.md`, `contract.md`, `checklist.md`, `status.md` from templates. (`relay.md` is created by later stages per § Relay Protocol — not seeded here.) Ensure Allowed Modifications are **disjoint** across siblings.

**AUDIT variation**: "Allowed Modifications" → "Audit Scope", "Forbidden Zones" → "Out of Scope", "Interfaces" → "Audit Criteria", "Test Requirements" → "Expected Output Format".

### Step 7: Boundary Overlap Check

Always when 2+ items exist. Extract Allowed Modifications, check path overlaps. Print matrix. If overlaps: suggest narrowing, ask confirmation.

### Step 8: Create Worktrees & Branches

Per `rules/collab-workflow.md` § Worktree Rules (Creation):

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
PROJECT=$(basename "$REPO_ROOT")
SLUG="{slug}"                       # e.g. user-auth
# feat → feature-{slug}, others → feature-{type}-{slug}
if [[ "$TYPE" == "feat" ]]; then
  BRANCH="feature-${SLUG}"
else
  BRANCH="feature-${TYPE_SHORT}-${SLUG}"  # e.g. feature-fix-login-crash
fi
WT_PATH="$(dirname "$REPO_ROOT")/${PROJECT}-${BRANCH}"

BASE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
git branch "$BRANCH" "$BASE_BRANCH"
git worktree add "$WT_PATH" "$BRANCH"
```

Seed artifacts into worktree, commit. Update `status.md` with absolute `Worktree Path`.

### Step 9: GitHub Issues + Batch Manifest

For each item, create a GitHub Issue directly (not via agent — avoids silent failures):

```bash
OWNER_REPO="$(gh repo view --json nameWithOwner -q '.nameWithOwner')"
ISSUE_URL=$(gh issue create \
  --repo "$OWNER_REPO" \
  --title "{TYPE}-NNN: {readable title}" \
  --body "## Objective\n...\n## Scope\n...\n## Checklist\n..." \
  --label "work-item" --label "status:planned")
```

Store issue number in `status.md`. Write `work/batches/{batch_id}.json`. Release planning lock.

### Step 10: Summary

Print table with absolute worktree paths, then next-step commands.

**MANDATORY NEXT-STEP TEMPLATE** — Print the block below as-is. Fill `«___»` slots with actual IDs. Do NOT add, remove, or reorder lines.

```
📋 다음 단계
  /work-scaffold «IDs»              # Cursor 없으면: --claude
  bash codex-run.sh «IDs»           # Codex 없으면: /work-impl «ID»
  /work-verify «AUDIT-NNN»          # AUDIT only — 없으면 이 줄 삭제
```

Fill rules:
- `«IDs»` → space-separated IDs (e.g., `PERF-154 PERF-155 PERF-156`)
- `«AUDIT-NNN»` → AUDIT ID if exists, otherwise delete line
- Lines, commands, order, comments — NEVER change
